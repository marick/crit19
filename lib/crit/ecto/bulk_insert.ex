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

    def many_to_many_structs(tx_result, schema, {first_source, second_source}) do
      for id1 <- tx_result[first_source], id2 <- tx_result[second_source] do
        apply(schema, :foreign_key_map, [id1, id2])
      end
    end
  end

  def simplify_transaction_results(result, desired) when not is_list(desired) do
    simplify_transaction_results(result, [desired])
  end

  def simplify_transaction_results({:error, _failing_step, changeset, _so_far}, _) do
    {:error, changeset}
  end

  def simplify_transaction_results({:ok, tx_result}, desired_keys) do
    extracted = Enum.reduce(desired_keys, %{}, fn desired, acc ->
      Map.put(acc, desired, tx_result[desired])
    end)

    {:ok, extracted}
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

  def cross_product_script(institution, kwlist) do
    config = Enum.into(kwlist, %{})
    
    fn tx_result ->
      Testable.many_to_many_structs(tx_result, config.schema, config.cross)
      |> insert_all_script(institution, config)
    end
  end

  def insert_all_script(structs, institution, kwlist) do
    config = Enum.into(kwlist, %{})
    insert_opts = Sql.multi_opts(institution)
    
    Multi.new
    |> Multi.insert_all(config.schema, config.schema, structs, insert_opts)
  end
  

  # These add multis onto existing multis

  def append_idlist_script(multi, structs_or_changesets, institution, kwlist) do
    Multi.append(multi, idlist_script(structs_or_changesets, institution, kwlist))
  end

  def append_id_collector(multi, kwlist) do
    config = Enum.into(kwlist, %{})

    add_id_collector = fn _repo, tx_result -> 
      Testable.collect_ids(tx_result, schema: config.schema)
    end

    multi
    |> Multi.run(config.ids, add_id_collector)
  end

  def append_cross_product_script(multi, institution, kwlist) do
    Multi.merge(multi, cross_product_script(institution, kwlist))
  end
end
