defmodule Crit.Ecto.MegaInsert do
  alias Crit.Sql
  alias Ecto.Multi

  defmodule Testable do
    def insert_key(schema, count), do: {schema, count}
    def desired_key?(desired_schema, {actual_schema, _count}),
      do: desired_schema == actual_schema
    def desired_key?(_schema, _key),
      do: false

    def collect_structs(tx_result, [schema: desired_schema]) do
      reducer = fn {key, value}, acc ->
        case desired_key?(desired_schema, key) do
          true ->
            [value | acc]
          false ->
            acc
        end
      end
      
      result = 
        tx_result
        |> Enum.reduce([], reducer)
        |> Enum.reverse
      {:ok, result}
      end

    def collect_ids(tx_result, [structs: struct_key]) do
      result = tx_result[struct_key] |> Enum.map(fn s -> s.id end)
      {:ok, result}
    end
  end

  def make_insertions(changesets_or_structs, institution, opts) do
    alias Crit.Ecto.MegaInsert.Testable
    
    config = Enum.into(opts, %{})
    
    add_insertion = fn {to_insert, count}, acc ->
      insert_opts = Sql.multi_opts(institution)
      result_key = Testable.insert_key(config.schema, count)
      Multi.insert(acc, result_key, to_insert, insert_opts)
    end
      
    changesets_or_structs
    |> Enum.with_index
    |> Enum.reduce(Multi.new, add_insertion)
  end

  def append_collecting(multi, opts) do
    alias Crit.Ecto.MegaInsert.Testable
    config = Enum.into(opts, %{})

    add_struct_collector = fn _repo, tx_results -> 
      Testable.collect_structs(tx_results, schema: config.schema)
    end

    add_id_collector = fn _repo, tx_results -> 
      Testable.collect_ids(tx_results, structs: config.structs)
    end

    multi
    |> Multi.run(config.structs, add_struct_collector)
    |> Multi.run(config.ids, add_id_collector)
  end
end
