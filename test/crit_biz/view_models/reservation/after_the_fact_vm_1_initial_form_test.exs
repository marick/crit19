defmodule CritBiz.ViewModels.Reservation.InitialFormTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
  alias Ecto.Changeset

  test "the starting changeset" do
    assert {task_memory, changeset} = VM.start
  end
end
  
