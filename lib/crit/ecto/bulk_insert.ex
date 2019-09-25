defmodule Crit.Ecto.BulkInsert do
  alias Crit.Sql
  alias Ecto.Multi

  defmodule Testable do
    def insert_key(schema, count), do: {schema, count}
    def desired_key?(desired_schema, {actual_schema, _count}),
      do: desired_schema == actual_schema
    def desired_key?(_schema, _key),
      do: false

    def collect_ids(tx_result, [schema: desired_schema]) do
      reducer = fn {key, value}, acc ->
        case desired_key?(desired_schema, key) do
          true ->
            [value.id | acc]
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

    def many_to_many_structs(tx_result, schema, first_source, second_source) do
      for id1 <- tx_result[first_source], id2 <- tx_result[second_source] do
        apply(schema, :new, [id1, id2])
      end
    end
  end

  # Main

  def make_insertions(structs, institution, opts) do
    alias Crit.Ecto.BulkInsert.Testable
    
    config = Enum.into(opts, %{})
    
    add_insertion = fn {to_insert, count}, acc ->
      insert_opts = Sql.multi_opts(institution)
      result_key = Testable.insert_key(config.schema, count)
      Multi.insert(acc, result_key, to_insert, insert_opts)
    end
      
    structs
    |> Enum.with_index
    |> Enum.reduce(Multi.new, add_insertion)
  end

  def append_ids(multi, opts) do
    alias Crit.Ecto.BulkInsert.Testable
    config = Enum.into(opts, %{})

    add_id_collector = fn _repo, tx_results -> 
      Testable.collect_ids(tx_results, schema: config.schema)
    end

    multi
    |> Multi.run(config.ids, add_id_collector)
  end

end
