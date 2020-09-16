defmodule CritBiz.ViewModels.Reservation.AfterTheFact.ValidateContext.Test do
  use Crit.DataCase
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
#  alias Ecto.Changeset
  alias Crit.Servers.UserTask

  setup do
    {task_memory, _} = VM.start(@institution)
    [task_memory: task_memory]
  end


  test "all errors", %{task_memory: task_memory} do
    params = %{"task_id" => task_memory.task_id,
               "responsible_person" => "",
               "date" => "",
              }
    {:error, :form, changeset} = VM.accept_context_form(params)

    changeset
    |> assert_error(responsible_person: "can't be blank",
                    date: "can't be blank")

    assert_task_memory_unchanged(task_memory)
  end


  def assert_task_memory_unchanged(task_memory) do 
    assert UserTask.get(task_memory.task_id) == task_memory
  end
end
  
