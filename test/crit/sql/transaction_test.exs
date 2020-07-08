defmodule Crit.Sql.TransactionTest do
  use Crit.DataCase
  alias Crit.Sql.Transaction
  alias CritBiz.ViewModels.Setup.BulkAnimalNew
  alias Crit.Setup.Schemas.Species
  alias Ecto.Changeset

  describe "handling transaction results" do
    test "on_ok ignores transaction errors" do
      transaction_error = {:error, :_step_key, :_failing_changeset, :_result_so_far}

      assert Transaction.on_ok(transaction_error, :_ok_action) == transaction_error
    end

    test "on_ok can return a specific key from the transaction result" do
      actual = {:ok, %{desired: "some value"} }

      assert Transaction.on_ok(actual, extract: :desired) == {:ok, "some value"}
    end

    test "on_error ignores previous successes" do
      assert {:ok, "done"} =
        Transaction.on_error({:ok, "done"}, :_destination_changeset, :_handlers)
    end      

    test "on_error operates on fields in the failing changeset" do
      original_changeset = Changeset.change(%BulkAnimalNew{})
      assert original_changeset.errors == []

      # I'm using species for the source of messages because it's a simple schema.
      failing_changeset =
        %Species{name: "bovine"}
        |> Changeset.change
        |> Changeset.add_error(:first_field, "this will affect `:name`")
        |> Changeset.add_error(:second_field, "transferred directly, msg ignored")

      first_handler = fn failing, original ->
        {msg, _} = failing.errors[:first_field]
        Changeset.add_error(original, :name, msg)
      end

      # You can add new error fields that don't correspond to the original schema.
      second_handler = fn _failing, original ->
        Changeset.add_error(original, :second_field, "ignore message")
      end
      
      {:error, result} = Transaction.on_error(
        {:error, :_step_key, failing_changeset, :_result_so_far},
        original_changeset, first_field: first_handler, second_field: second_handler)

      assert_errors(result,
        name: "this will affect `:name`",
        second_field: "ignore message")
    end
  end
end

