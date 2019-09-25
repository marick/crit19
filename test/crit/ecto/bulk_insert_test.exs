defmodule Crit.Ecto.BulkInsertTest do
  use Crit.DataCase
  alias Crit.Ecto.BulkInsert
  alias Crit.Usables.Write
  alias Crit.Ecto.BulkInsert.Testable
  alias Ecto.Datespan
  alias Crit.Sql
  alias Ecto.Multi
  alias Crit.Usables

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2011-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

  @before_service %Write.ServiceGap{ gap: Datespan.strictly_before(@date),
                                     reason: "strictly before" }
  @after_service %Write.ServiceGap{ gap: Datespan.date_and_after(@later_date),
                                    reason: "date and after" }

  @service_gaps [@before_service, @after_service]

  @animal Factory.build(:animal)
  

  def assert_right_dates [before_service, after_service] do 
    assert_strictly_before(before_service.gap, @date)
    assert_date_and_after(after_service.gap,   @later_date)
  end


  describe "insertion_script" do
    test "insertion where nothing is done with the result" do
      assert {:ok, _result} =
        @service_gaps
        |> BulkInsert.insertion_script(@institution, schema: Write.ServiceGap)
        |> Sql.transaction(@institution)

      assert [before_service, after_service] =
        Crit.Sql.all(Write.ServiceGap, @institution)
      assert_right_dates [before_service, after_service]      
    end
  end

  describe "can also ask for the ids of the insertion" do
    setup do  
      opts = [schema: Write.ServiceGap, ids: :gap_ids]

      {:ok, tx_results} =
        @service_gaps
        |> BulkInsert.idlist_script(@institution, opts)
        |> Sql.transaction(@institution)

      [tx_results: tx_results]
    end

    test "it returns collected ids", %{tx_results: tx_results} do
      [before_id, after_id] = tx_results.gap_ids

      before_service = Sql.get(Write.ServiceGap, before_id, @institution)
      after_service = Sql.get(Write.ServiceGap, after_id, @institution)
      assert_right_dates [before_service, after_service]      
    end
  end

  describe "cross_product structs can be inserted" do
    test "this is the step-by-step approach" do 
      animal_opts =
        [schema: Write.Animal,             ids: :animal_ids]
      service_gap_opts =
        [schema: Write.ServiceGaps,        ids: :service_gap_ids]
      cross_opts =
        [schema: Write.AnimalServiceGap, cross: {:animal_ids, :service_gap_ids}]
      
      
      {:ok, tx_result} = 
        Multi.new
        |> BulkInsert.append_idlist_script([@animal], @institution, animal_opts)
        |> BulkInsert.append_idlist_script(@service_gaps, @institution, service_gap_opts)
        |> BulkInsert.append_cross_product_script(@institution, cross_opts)
        |> Sql.transaction(@institution)

      assert animal = Usables.get_complete_animal_by_name(@animal.name, @institution)
      assert animal.name == @animal.name
      assert [animal.id] == tx_result.animal_ids

      # I will probably someday regret assuming these are returned in insertion order.
      assert [%{reason: before_service}, %{reason: after_service}] = animal.service_gaps
      assert before_service == @before_service.reason
      assert after_service == @after_service.reason
    end
  end

  # Tests for support functions

  describe "collecting ids" do
    test "no filtering needed" do
      transaction_result_so_far =
        %{Testable.insert_key(Write.ServiceGap, 0) => %{id: :some_gap_id},
          Testable.insert_key(Write.ServiceGap, 1) => %{id: :another_gap_id},
         }
      # Note that order is preserved.
      assert {:ok, [:some_gap_id, :another_gap_id]} =
        Testable.collect_ids(transaction_result_so_far, schema: Write.ServiceGap)
    end
    
    test "some keys need to be ignored" do
      transaction_result_so_far =
        %{Testable.insert_key(Write.ServiceGap, 0) =>    %{id: :some_gap_id},
          :some_random_key                   =>    :SOME_RANDOM_VALUE,
          Testable.insert_key(:wrong_schema, 0) => :SOME_OTHER_RANDOM_VALUE,
          Testable.insert_key(Write.ServiceGap, 1) =>    %{id: :another_gap_id}
         }

      assert {:ok, [:some_gap_id, :another_gap_id]} =
        Testable.collect_ids(transaction_result_so_far, schema: Write.ServiceGap)
    end


    test "cross product and creation of many-to-many structs" do
      tx_results =
        %{animal_ids: [1, 2], service_gap_ids: [11, 22]}
      cross_product =
        Testable.many_to_many_structs(
          tx_results,
          Write.AnimalServiceGap,
          {:animal_ids, :service_gap_ids})
      
      assert Enum.at(cross_product, 0).animal_id == 1
      assert Enum.at(cross_product, 0).service_gap_id == 11
    end
  end
end
