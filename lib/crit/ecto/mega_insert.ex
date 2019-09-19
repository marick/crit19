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

  end

  def prepare(changesets_or_structs, institution, opts) do
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

  def prepare_and_collect(changesets_or_structs, institution, opts) do
    alias Crit.Ecto.MegaInsert.Testable
    config = Enum.into(opts, %{})

    add_struct_collector = fn _repo, tx_results -> 
      Testable.collect_structs(tx_results, schema: config.schema)
    end

    changesets_or_structs
    |> prepare(institution, opts)
    |> Multi.run(config.structs, add_struct_collector)
  end

  
end
