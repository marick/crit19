defmodule Crit.Ecto.BulkInsertTest do
  use Crit.DataCase
  alias Crit.Ecto.BulkInsert
  alias Crit.Usables.ServiceGap
  alias Crit.Ecto.BulkInsert.Testable
  alias Ecto.Datespan
  alias Crit.Sql

  @before_service_cs ServiceGap.changeset(
    gap: Datespan.strictly_before(@date),
    reason: "strictly before"
  )

  @after_service_cs ServiceGap.changeset(
    gap: Datespan.date_and_after(@later_date),
    reason: "date and after"
  )

  @service_gap_cs_list [@before_service_cs, @after_service_cs]


  def assert_right_dates [before_service, after_service] do 
    assert_strictly_before(before_service.gap, @date)
    assert_date_and_after(after_service.gap,   @later_date)
  end


  describe "insertion_script" do
    test "insertion where nothing is done with the result" do
      assert {:ok, _result} =
        @service_gap_cs_list
        |> BulkInsert.insertion_script(@institution, schema: ServiceGap)
        |> Sql.transaction(@institution)

      assert [before_service, after_service] =
        Crit.Sql.all(ServiceGap, @institution)
      assert_right_dates [before_service, after_service]      
    end
  end

  describe "can also ask for the ids of the insertion" do
    setup do  
      opts = [schema: ServiceGap, ids: :gap_ids]

      {:ok, tx_result} =
        @service_gap_cs_list
        |> BulkInsert.idlist_script(@institution, opts)
        |> Sql.transaction(@institution)

      [tx_result: tx_result]
    end

    test "it returns collected ids", %{tx_result: tx_result} do
      [before_id, after_id] = tx_result.gap_ids

      before_service = Sql.get(ServiceGap, before_id, @institution)
      after_service = Sql.get(ServiceGap, after_id, @institution)
      assert_right_dates [before_service, after_service]      
    end
  end

  # Tests for support functions

  describe "collecting ids" do
    test "no filtering needed" do
      transaction_result_so_far =
        %{Testable.insert_key(ServiceGap, 0) => %{id: :some_gap_id},
          Testable.insert_key(ServiceGap, 1) => %{id: :another_gap_id},
         }
      # Note that order is preserved.
      assert {:ok, [:some_gap_id, :another_gap_id]} =
        Testable.collect_ids(transaction_result_so_far, schema: ServiceGap)
    end
    
    test "some keys need to be ignored" do
      transaction_result_so_far =
        %{Testable.insert_key(ServiceGap, 0) =>    %{id: :some_gap_id},
          :some_random_key                   =>    :SOME_RANDOM_VALUE,
          Testable.insert_key(:wrong_schema, 0) => :SOME_OTHER_RANDOM_VALUE,
          Testable.insert_key(ServiceGap, 1) =>    %{id: :another_gap_id}
         }

      assert {:ok, [:some_gap_id, :another_gap_id]} =
        Testable.collect_ids(transaction_result_so_far, schema: ServiceGap)
    end
  end
end
