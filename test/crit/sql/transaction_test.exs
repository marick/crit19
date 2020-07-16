defmodule Crit.Sql.TransactionTest do
  use Crit.DataCase
  alias Crit.Sql.Transaction
  alias Ecto.Changeset

  describe "simplifying transaction results" do
    test "all errors are simplified the same way" do
      failing_changeset = %Changeset{}  # nothing is done with the inside
      index = 1

      {:error, {Any.Old.Schema, index}, failing_changeset, :_result_so_far}
      |> Transaction.simplify_result(:ignored_second_argument)
      |> assert_equals({:error, index, failing_changeset})
    end

    test "the results can be extracted, ordered by `id`" do
      in_order = [%{id: 1}, %{id: 2}, %{id: 3}, %{id: 4}]
      tx_result =
        Enum.shuffle(in_order)      
        |> Enum.map(fn tx_result -> {{Any.Old.Schema, tx_result.id}, tx_result} end)
        |> Map.new
      
      {:ok, tx_result}
      |> Transaction.simplify_result(:return_inserted_values)
      |> assert_equals({:ok, in_order})
    end

    test "a specific tag's value can be extracted" do
      {:ok, %{:animal_ids => [1, 2, 3]}}
      |> Transaction.simplify_result(extract: :animal_ids)
      |> assert_equals({:ok, [1, 2, 3]})
    end
  end
end

