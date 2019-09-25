defmodule Crit.Ecto.BulkInsertTest do
  use Crit.DataCase
  alias Crit.Ecto.BulkInsert
  alias Crit.Usables.{ServiceGap}  # Convenient for testing
  alias Crit.Usables.Write.{AnimalServiceGap}  # Convenient for testing
  alias Crit.Ecto.BulkInsert.Testable
  alias Crit.Sql

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2011-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

  @changesets ServiceGap.initial_changesets(
    %{ start_date: @iso_date,
       end_date: @later_iso_date
    })
    |> elem(1)

  def assert_right_dates [before_service, after_service] do 
    assert_strictly_before(before_service.gap, @date)
    assert_date_and_after(after_service.gap,   @later_date)
  end


  describe "make_insertions" do
    test "insertion where nothing is done with the result" do
      assert {:ok, _result} =
        @changesets
        |> BulkInsert.make_insertions(@institution, schema: ServiceGap)
        |> Sql.transaction(@institution)

      assert [before_service, after_service] =
        Crit.Sql.all(ServiceGap, @institution)
      assert_right_dates [before_service, after_service]      
    end
  end

  describe "append_ids" do
    setup do  
      opts = [schema: ServiceGap, ids: :gap_ids]

      {:ok, tx_results} =
        @changesets
        |> BulkInsert.make_insertions(@institution, opts)
        |> BulkInsert.append_ids(opts)
        |> Sql.transaction(@institution)
      
      [tx_results: tx_results]
    end

    test "it returns collected ids", %{tx_results: tx_results} do
      [before_id, after_id] = tx_results.gap_ids

      before_service = Sql.get(ServiceGap, before_id, @institution)
      after_service = Sql.get(ServiceGap, after_id, @institution)
      assert_right_dates [before_service, after_service]      
    end
  end

  @tag :skip
  test "cross_product structs can be inserted" do
    
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


    test "cross product and creation of many-to-many structs" do
      tx_results =
        %{animal_ids: [1, 2], service_gap_ids: [11, 22]}
      cross_product =
        Testable.many_to_many_structs(
          tx_results,
          AnimalServiceGap,
          :animal_ids, :service_gap_ids)
      
      assert Enum.at(cross_product, 0).animal_id == 1
      assert Enum.at(cross_product, 0).service_gap_id == 11
    end
  end
end
