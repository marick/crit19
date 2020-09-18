defmodule CritBiz.ViewModels.Reservation.AfterTheFactTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
  alias Crit.Servers.UserTask
  use FlowAssertions

  describe "processing of Animals" do
    # Procedures are the same with name changes

    setup do
      %{task_id: task_id} = UserTask.start(VM.Forms.Animals)
      [task_id: task_id]
    end
      
    test "success", %{task_id: task_id} do
      params = %{"chosen_animal_ids" => ["8", "1"],
                 "task_id" => task_id}
      
      assert {:ok, data, ^task_id} =
        UserTask.pour_into_struct(params, VM.Forms.Animals)
      
      assert_lists_equal [1, 8], data.chosen_animal_ids
    end

    test "no such task id", %{task_id: task_id} do
      UserTask.delete(task_id)
      params = %{"chosen_animal_ids" => ["8", "1"],
                 "task_id" => task_id}

      assert {:task_expiry, UserTask.expiry_message} ==
        UserTask.pour_into_struct(params, VM.Forms.Animals)
    end

    test "no animals chosen", %{task_id: task_id} do
      params = %{"task_id" => task_id}

      assert {:error, changeset, ^task_id} =
        UserTask.pour_into_struct(params, VM.Forms.Animals)
      assert %{chosen_animal_ids: [_]} = errors_on(changeset)
    end
  end  
end
