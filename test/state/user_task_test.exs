defmodule Crit.State.UserTaskTest do 
  use ExUnit.Case, async: true
  alias Crit.State.UserTask
  alias CritWeb.Reservations.AfterTheFactStructs, as: Scratch
  import Crit.Assertions.Map

  test "How controllers use UserTask" do
    # For readability, return value of `update` is shown in another task
    
    %Scratch.State{task_id: task_id} = UserTask.start(Scratch.State)

    (%Scratch.State{} = UserTask.get(task_id))
    |> assert_nothing(:chosen_animal_ids)
    |> assert_field(task_id: task_id)

    # task_id gets put in a form's `input type=hidden`
   UserTask.store(%Scratch.Animals{
          chosen_animal_ids: [1, 2, 3],
          task_id: task_id})

    (%Scratch.State{} = UserTask.get(task_id))
    |> assert_fields(chosen_animal_ids: [1, 2, 3],
                     task_id: task_id)

    # Confirm that struct store merges
    UserTask.store(%Scratch.Procedures{
          chosen_procedure_ids: [3, 2, 1],
          task_id: task_id})

    (%Scratch.State{} = UserTask.get(task_id))
    |> assert_fields(chosen_animal_ids: [1, 2, 3],
                     chosen_procedure_ids: [3, 2, 1],
                     task_id: task_id)

    # Show overwrite and how store can take options.
    struct = %Scratch.Procedures{
      chosen_procedure_ids: [:new, :new, :new],
      task_id: task_id}
    UserTask.store(struct, timeslot_id: 88)

    (%Scratch.State{} = UserTask.get(task_id))
    |> assert_fields(chosen_animal_ids: [1, 2, 3],
                     chosen_procedure_ids: [:new, :new, :new],
                     task_id: task_id)

    UserTask.delete(task_id)
    assert nil == UserTask.get(task_id)
  end

  test "update returns the whole state" do
    %Scratch.State{task_id: task_id} = UserTask.start(Scratch.State)

    UserTask.store(%Scratch.Animals{
          chosen_animal_ids: [1, 2, 3],
          task_id: task_id})
    
    actual = UserTask.store(%Scratch.Procedures{
          chosen_procedure_ids: [3, 2, 1],
          task_id: task_id})

    assert %Scratch.State{
      chosen_animal_ids: [1, 2, 3],
      chosen_procedure_ids: [3, 2, 1],
      task_id: task_id} = actual
  end

  # ----------------------------------------------------------------------------
  defstruct task_id: nil, some_array: [], keyword: false

  test "you can start with some data" do
    initial = %__MODULE__{some_array: [1, 2, 3]}
    assert_field(initial, task_id: nil)

    (%__MODULE__{} = UserTask.start(__MODULE__, initial, keyword: true))
    |> assert_fields(some_array: [1, 2, 3],
                     keyword: true,
                     task_id: &is_binary/1)
  end
end

