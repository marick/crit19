defmodule CritBiz.ViewModels.Reservation.InitialFormTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
  alias Crit.Servers.UserTask

  @task_id UserTask.new_id()

  setup do 
    given UserTask.new_id, [], do: @task_id
    UserTask.delete(@task_id)
    :ok
  end

  test "the starting changeset" do
    assert {task_memory, changeset} = VM.start(@institution)

    task_memory
    |> assert_fields(task_id: @task_id,
                     institution: @institution)

    changeset
    |> assert_no_changes
  end
end
  
