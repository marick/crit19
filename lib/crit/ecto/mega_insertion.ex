defmodule Ecto.MegaInsertion do
  defmacro __using__(
    individual_result_prefix: individual_result_prefix,
    idlist_result_prefix: id_result_prefix) do
    
    quote do
      alias Ecto.Multi
      alias Crit.Sql

      defp tx_key(index), do: {unquote(individual_result_prefix), index}
      defp is_tx_key?({unquote(individual_result_prefix), _count}), do: true
      defp is_tx_key?(_), do: false

      defp reduce_to_idlist(_repo, tx_result) do
        reducer = fn {key, value}, acc ->
          case is_tx_key?(key) do
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

      def multi_insert(changesets, institution) do
        add_insertion = fn {changeset, index}, acc ->
          Multi.insert(acc, tx_key(index), changeset, Sql.multi_opts(institution))
        end
        
        changesets
        |> Enum.with_index
        |> Enum.reduce(Multi.new, add_insertion)
      end

      def multi_collecting_ids(changesets, institution) do
        multi_insert(changesets, institution)
        |> Multi.run(unquote(id_result_prefix), &reduce_to_idlist/2)
      end

      def resulting_ids({:ok, transaction_result}) do
        Map.fetch!(transaction_result, unquote(id_result_prefix))
      end

      # These are really for testing. 
      
      def run(changesets_or_structs, institution) do
        changesets_or_structs
        |> multi_insert(institution)
        |> Sql.transaction(institution)
      end

      def run_for_ids(changesets_or_structs, institution) do
        changesets_or_structs
        |> multi_collecting_ids(institution)
        |> Sql.transaction(institution)
        |> resulting_ids
      end
    end
  end
end
