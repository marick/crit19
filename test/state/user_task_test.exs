defmodule Crit.State.UserTaskTest do 
  use ExUnit.Case, async: true
  alias Crit.State.UserTask
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
  use FlowAssertions.NoValueA, no_value: :nothing
  import FlowAssertions.MapA

  test "How controllers use UserTask" do
    # For readability, return value of `update` is shown in another task
    
    %VM.TaskMemory{task_id: task_id} = UserTask.start(VM.TaskMemory)

    (%VM.TaskMemory{} = UserTask.get(task_id))
    |> assert_no_value(:chosen_animal_ids)
    |> assert_field(task_id: task_id)

    # task_id gets put in a form's `input type=hidden`
   UserTask.remember_relevant(%VM.ActionData.Animals{
          chosen_animal_ids: [1, 2, 3],
          task_id: task_id})

    (%VM.TaskMemory{} = UserTask.get(task_id))
    |> assert_fields(chosen_animal_ids: [1, 2, 3],
                     task_id: task_id)

    # Confirm that struct remember_relevant merges
    UserTask.remember_relevant(%VM.ActionData.Procedures{
          chosen_procedure_ids: [3, 2, 1],
          task_id: task_id})

    (%VM.TaskMemory{} = UserTask.get(task_id))
    |> assert_fields(chosen_animal_ids: [1, 2, 3],
                     chosen_procedure_ids: [3, 2, 1],
                     task_id: task_id)

    # Show overwrite and how remember_relevant can take options.
    struct = %VM.ActionData.Procedures{
      chosen_procedure_ids: [:new, :new, :new],
      task_id: task_id}
    UserTask.remember_relevant(struct, timeslot_id: 88)

    (%VM.TaskMemory{} = UserTask.get(task_id))
    |> assert_fields(chosen_animal_ids: [1, 2, 3],
                     chosen_procedure_ids: [:new, :new, :new],
                     task_id: task_id)

    UserTask.delete(task_id)
    assert nil == UserTask.get(task_id)
  end

  test "update returns the whole state" do
    %VM.TaskMemory{task_id: task_id} = UserTask.start(VM.TaskMemory)

    UserTask.remember_relevant(%VM.ActionData.Animals{
          chosen_animal_ids: [1, 2, 3],
          task_id: task_id})
    
    actual = UserTask.remember_relevant(%VM.ActionData.Procedures{
          chosen_procedure_ids: [3, 2, 1],
          task_id: task_id})

    assert %VM.TaskMemory{
      chosen_animal_ids: [1, 2, 3],
      chosen_procedure_ids: [3, 2, 1],
      task_id: task_id} = actual
  end

  test "can put a single value" do
    %VM.TaskMemory{task_id: task_id} = UserTask.start(VM.TaskMemory)
    UserTask.remember_relevant(%VM.ActionData.NonUseValues{
          date: "some date",
          task_id: task_id})

    
    UserTask.put(task_id, :species_id, "some species id")

    # new value stored
    assert "some species id" = UserTask.get(task_id).species_id
    # old value retained
    assert "some date" = UserTask.get(task_id).date
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

