defmodule CritBiz.ViewModels.Reservation.AfterTheFactTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
  alias Ecto.Timespan
  alias Crit.State.UserTask
  use FlowAssertions

  describe "processing of NonUseValues" do
    test "success" do
      params = %{species_id: to_string(@bovine_id),
                 date: "2019-01-01",
                 date_showable_date: "January 1, 2019",
                 responsible_person: "dster", 
                 timeslot_id: "1",
                 institution: @institution,
                 task_id: "uuid"}

      expected_span =
        Timespan.from_date_time_and_duration(~D[2019-01-01], ~T[08:00:00], 4 * 60)

      assert {:ok, data, "uuid"} =
        UserTask.pour_into_struct(params, VM.Form.NonUseValues)
      data
      |> assert_fields(
           species_id: @bovine_id,
           date: ~D[2019-01-01],
           timeslot_id: 1,
           responsible_person: "dster",
           span: expected_span
         )
    end
  end

  describe "processing of Animals" do
    # Procedures are the same with name changes

    setup do
      %{task_id: task_id} = UserTask.start(VM.Form.Animals)
      [task_id: task_id]
    end
      
    test "success", %{task_id: task_id} do
      params = %{"chosen_animal_ids" => ["8", "1"],
                 "task_id" => task_id}
      
      assert {:ok, data, ^task_id} =
        UserTask.pour_into_struct(params, VM.Form.Animals)
      
      assert_lists_equal [1, 8], data.chosen_animal_ids
    end

    test "no such task id", %{task_id: task_id} do
      UserTask.delete(task_id)
      params = %{"chosen_animal_ids" => ["8", "1"],
                 "task_id" => task_id}

      assert {:task_expiry, UserTask.expiry_message} ==
        UserTask.pour_into_struct(params, VM.Form.Animals)
    end

    test "no animals chosen", %{task_id: task_id} do
      params = %{"task_id" => task_id}

      assert {:error, changeset, ^task_id} =
        UserTask.pour_into_struct(params, VM.Form.Animals)
      assert %{chosen_animal_ids: [_]} = errors_on(changeset)
    end
  end  
end
