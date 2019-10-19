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
  end


  # These produce multis from data

  def insertion_script(structs_or_changesets, institution, kwlist) do
    config = Enum.into(kwlist, %{})
    
    add_insertion = fn {to_insert, count}, acc ->
      insert_opts = Sql.multi_opts(institution)
      result_key = Testable.insert_key(config.schema, count)
      Multi.insert(acc, result_key, to_insert, insert_opts)
    end
      
    structs_or_changesets
    |> Enum.with_index
    |> Enum.reduce(Multi.new, add_insertion)
  end

  def idlist_script(structs_or_changesets, institution, kwlist) do
    structs_or_changesets
    |> insertion_script(institution, kwlist)
    |> append_id_collector(kwlist)
  end
  
  def append_id_collector(multi, kwlist) do
    config = Enum.into(kwlist, %{})

    add_id_collector = fn _repo, tx_result -> 
      Testable.collect_ids(tx_result, schema: config.schema)
    end

    multi
    |> Multi.run(config.ids, add_id_collector)
  end
end
