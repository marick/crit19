defmodule Crit.Ecto.MegaInsertTest do
  use Crit.DataCase
  alias Crit.Ecto.MegaInsert
  alias Crit.Usables.{ServiceGap, AnimalServiceGap}  # Convenient for testing
  alias Crit.Ecto.MegaInsert.Testable
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
        |> MegaInsert.make_insertions(@institution, schema: ServiceGap)
        |> Sql.transaction(@institution)

      assert [before_service, after_service] =
        Crit.Sql.all(ServiceGap, @institution)
      assert_right_dates [before_service, after_service]      
    end
  end

  describe "append_collecting" do
    setup do  
      opts = [schema: ServiceGap, structs: :gaps, ids: :gap_ids]

      {:ok, tx_results} =
        @changesets
        |> MegaInsert.make_insertions(@institution, opts)
        |> MegaInsert.append_collecting(opts)
        |> Sql.transaction(@institution)
      
      [tx_results: tx_results]
    end
    
    test "it returns collected structures", %{tx_results: tx_results} do
      [before_service, after_service] = tx_results.gaps
      assert_right_dates [before_service, after_service]      
    end

    test "it returns collected ids", %{tx_results: tx_results} do
      [before_service, after_service] = tx_results.gaps
      [before_id, after_id] = tx_results.gap_ids

      assert before_service.id == before_id
      assert after_service.id == after_id
    end
    
    test "... and things are in fact put in the database", %{tx_results: tx_results} do
      [before_id, after_id] = tx_results.gap_ids

      before_service = Sql.get(ServiceGap, before_id, @institution)
      after_service = Sql.get(ServiceGap, after_id, @institution)
      assert_right_dates [before_service, after_service]      
    end
    
  end

  test "cross product and structural creation" do
    tx_results =
      %{animal_ids: [1, 2], service_gap_ids: [11, 22]}
    cross_product =
      MegaInsert.connection_records(
        tx_results,
        AnimalServiceGap,
        :animal_ids, :service_gap_ids)

    assert Enum.at(cross_product, 0).animal_id == 1
    assert Enum.at(cross_product, 0).service_gap_id == 11
  end



  # Tests for support functions

  describe "collecting insertion results" do
    test "no filtering needed" do
      transaction_result_so_far =
        %{Testable.insert_key(ServiceGap, 0) => :some_gap_struct,
          Testable.insert_key(ServiceGap, 1) => :another_gap_struct,
         }
      # Note that order is preserved.
      assert {:ok, [:some_gap_struct, :another_gap_struct]} =
        Testable.collect_structs(transaction_result_so_far, schema: ServiceGap)
    end
    
    test "some keys need to be ignored" do
      transaction_result_so_far =
        %{Testable.insert_key(ServiceGap, 0) =>    :some_gap_struct,
          :some_random_key                   =>    :SOME_RANDOM_VALUE,
          Testable.insert_key(:wrong_schema, 0) => :SOME_OTHER_RANDOM_VALUE,
          Testable.insert_key(ServiceGap, 1) =>    :another_gap_struct,
         }

      assert {:ok, [:some_gap_struct, :another_gap_struct]} =
        Testable.collect_structs(transaction_result_so_far, schema: ServiceGap)
    end
  end
end
