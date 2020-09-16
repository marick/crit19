defmodule CritBiz.ViewModels.Reservation.AfterTheFact.StandardTaskHandlingTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
  alias Crit.Servers.UserTask

  @task_id UserTask.new_id()

  setup do 
    UserTask.delete(@task_id)
    given UserTask.new_id, [], do: @task_id 
    :ok
  end
  
  test "the single test of standard task-timeout handling" do
    actual = VM.accept_context_form(%{"task_id" => @task_id}) # no task id
    assert actual == {:error, :expired_task, UserTask.expiry_message}
  end
end
