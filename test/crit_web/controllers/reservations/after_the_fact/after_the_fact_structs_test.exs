defmodule CritWeb.Reservations.AfterTheFactStructsTest do
  use Crit.DataCase, async: true
  alias CritWeb.Reservations.AfterTheFactStructs, as: Scratch
  alias Ecto.Timespan
  alias Crit.State.UserTask

  describe "processing of SpeciesAndTime" do
    test "success" do
      params = %{species_id: to_string(@bovine_id),
                 date: "2019-01-01",
                 date_showable_date: "January 1, 2019",
                 timeslot_id: "1",
                 institution: @institution,
                 task_id: "uuid"}

      expected_span =
        Timespan.from_date_time_and_duration(~D[2019-01-01], ~T[08:00:00], 4 * 60)

      assert {:ok, data} = UserTask.pour_into_struct(params, Scratch.SpeciesAndTime)
      data
      |> assert_fields(
           species_id: @bovine_id,
           date: ~D[2019-01-01],
           timeslot_id: 1,
           span: expected_span
         )
    end
  end


  describe "processing of Animals" do
    test "success" do
      params = %{"chosen_animal_ids" => ["8", "1"],
                 "task_id" => "uuid", "institution" => @institution}

      assert {:ok, data} = UserTask.pour_into_struct(params, Scratch.Animals)
      
      assert_lists_equal [1, 8], data.chosen_animal_ids
      assert "uuid" == data.task_id
    end

    @tag :skip
    test "emptiness is rejected" do
      params = %{"task_id" => "uuid"}

      assert {:error, changeset} = UserTask.pour_into_struct(params, Scratch.Animals)
    end
    
  end  
end
