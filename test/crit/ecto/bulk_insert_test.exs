defmodule Crit.Ecto.BulkInsertTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.Procedure
  alias Crit.Ecto.BulkInsert
  alias Crit.Ecto.BulkInsert.Testable
  alias Crit.Sql

  @procedures [%Procedure{name: "spay"}, %Procedure{name: "physical exam"}]

  describe "insertion_script" do
    test "insertion where nothing is done with the result" do
      assert {:ok, _result} =
        @procedures
        |> BulkInsert.insertion_script(@institution, schema: Procedure)
        |> Sql.transaction(@institution)

      # Note: by default, Ecto orders return values by ids
      assert [%{name: "spay"}, %{name: "physical exam"}] =
        Sql.all(Procedure, @institution)
    end
  end

  describe "can also ask for the ids of the insertion" do
    setup do  
      opts = [schema: Procedure, ids: :procedure_ids]

      {:ok, tx_result} =
        @procedures
        |> BulkInsert.idlist_script(@institution, opts)
        |> Sql.transaction(@institution)

      [tx_result: tx_result]
    end

    test "it returns collected ids", %{tx_result: tx_result} do
      [spay_id, physical_exam_id] = tx_result.procedure_ids

      %{name: "spay"} = Sql.get(Procedure, spay_id, @institution)
      %{name: "physical exam"} = Sql.get(Procedure, physical_exam_id, @institution)
    end
  end

  # Tests for support functions

  describe "collecting ids" do
    test "no filtering needed" do
      transaction_result_so_far =
        %{Testable.insert_key(Procedure, 0) => %{id: :some_id},
          Testable.insert_key(Procedure, 1) => %{id: :another_id},
         }
      # Note that order is preserved.
      assert {:ok, [:some_id, :another_id]} =
        Testable.collect_ids(transaction_result_so_far, schema: Procedure)
    end
    
    test "some keys need to be ignored" do
      transaction_result_so_far =
        %{Testable.insert_key(Procedure, 0) =>    %{id: :some_id},
          :some_random_key                   =>    :SOME_RANDOM_VALUE,
          Testable.insert_key(:wrong_schema, 0) => :SOME_OTHER_RANDOM_VALUE,
          Testable.insert_key(Procedure, 1) =>    %{id: :another_id}
         }

      assert {:ok, [:some_id, :another_id]} =
        Testable.collect_ids(transaction_result_so_far, schema: Procedure)
    end
  end
end
