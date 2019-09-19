defmodule Crit.Ecto.MegaInsertTest do
  use Crit.DataCase
  alias Crit.Ecto.MegaInsert
  alias Crit.Usables.{ServiceGap}  # Convenient for testing
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

  def assert_right_dates [before_service, after_service] do 
    assert_strictly_before(before_service.gap, @date)
    assert_date_and_after(after_service.gap,   @later_date)
  end


  describe "make_insertions" do
    test "insertion where nothing is done with the result" do
      assert {:ok, _result} =
        @changesets
        |> MegaInsert.make_insertions(@default_short_name, schema: ServiceGap)
        |> Sql.transaction(@default_short_name)

      assert [before_service, after_service] =
        Crit.Sql.all(ServiceGap, @default_short_name)
      assert_right_dates [before_service, after_service]      
    end
  end

  describe "append_collecting" do
    setup do  
      opts = [schema: ServiceGap, structs: :gaps, ids: :gap_ids]

      {:ok, tx_results} =
        @changesets
        |> MegaInsert.make_insertions(@default_short_name, opts)
        |> MegaInsert.append_collecting(opts)
        |> Sql.transaction(@default_short_name)
      
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

      before_service = Sql.get(ServiceGap, before_id, @default_short_name)
      after_service = Sql.get(ServiceGap, after_id, @default_short_name)
      assert_right_dates [before_service, after_service]      
    end
    
  end


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
