defmodule Crit.Ecto.MegaInsertTest do
  use Crit.DataCase
  alias Crit.Ecto.MegaInsert
  alias Crit.Usables.{ServiceGap}  # Convenient for testing
  alias Crit.Ecto.MegaInsert.Testable
  alias Crit.Sql
  alias Ecto.Datespan

  @changesets ServiceGap.initial_changesets(
    %{ start_date: "2012-12-12",
       end_date: "2111-11-11"
    })

  describe "prepare" do
    test "insertion where nothing is done with the result" do
      assert {:ok, _result} =
        @changesets
        |> MegaInsert.prepare(@default_short_name, schema: ServiceGap)
        |> Sql.transaction(@default_short_name)

      assert [before_service, after_service] =
        Crit.Sql.all(ServiceGap, @default_short_name)
      assert_strictly_before(before_service.gap, ~D[2012-12-12])
      assert_date_and_after(after_service.gap,   ~D[2111-11-11])
    end
  end

  describe "prepare and collect" do
    setup do
      assert {:ok, tx_results} =
        @changesets
        |> MegaInsert.prepare_and_collect(@default_short_name,
               schema: ServiceGap, structs: :gaps, ids: :struct_ids)
        |> Sql.transaction(@default_short_name)

      [tx_results: tx_results]
    end
      
    
    test "it returns collected structures", %{tx_results: tx_results} do
      [before_service, after_service] = tx_results.gaps
      IO.inspect tx_results
      assert_strictly_before(before_service.gap, ~D[2012-12-12])
      assert_date_and_after(after_service.gap,   ~D[2111-11-11])
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
