defmodule CritBiz.ViewModels.Reservation.AfterTheFact.ValidateContext.Test do
  use Crit.DataCase
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
#  alias Ecto.Changeset
  alias Crit.Servers.UserTask
  alias Ecto.Timespan
  use Crit.Params.BuildWorkflow
    
  setup do
    {:ok, task_memory, _} = VM.start(@institution)

    
    [task_memory: task_memory,
     test_data: build_step(
       module_under_test: VM,
       exemplars: [
         valid: %{params: to_strings(%{species_id: @bovine_id, 
                                       date: "2019-01-01",
                                       date_showable_date: "January 1, 2019",
                                       responsible_person: "dster", 
                                       timeslot_id: 1,
                                       task_id: task_memory.task_id}),
                  categories: [:valid]}
       ]
     )]
  end

  test "success", %{test_data: test_data} do
    params = test_data.exemplars.valid.params

    assert {:ok, new_task_memory, animals} = VM.accept_context_form(params)

    # Task header would probably be better placed in the form data. OK for now
    expected_span =
      Timespan.from_date_time_and_duration(~D[2019-01-01], ~T[08:00:00], 4 * 60)

    new_task_memory
    |> assert_fields(species_id: @bovine_id,
                     responsible_person: "dster",
                     date: ~D[2019-01-01],
                     timeslot_id: 1,
                     span: expected_span,
                     task_header: safely_contains([~r/Step 2: Choose animals/,
                                                   ~r/January 1, 2019/,
                                                   ~r/morning/]))

    IO.puts "Use a mock"
    assert animals == []
    
  end

  test "all errors", %{task_memory: task_memory} do
    params = %{"task_id" => task_memory.task_id,
               "responsible_person" => "",
               "date" => "",
              }
    assert {:error, :form, new_task_memory, changeset} = VM.accept_context_form(params)

    changeset
    |> assert_error(responsible_person: "can't be blank",
                    date: "can't be blank")

    new_task_memory
    |> assert_same_map(task_memory)
  end



  defp safely_contains(descriptors) when is_list(descriptors) do
    fn actual -> 
      for d <- descriptors, do: safely_contains(d).(actual)
    end
  end  

  defp safely_contains(descriptor) do
    fn actual ->
      assert_good_enough(Phoenix.HTML.safe_to_string(actual), descriptor)
      true
    end
  end


  def assert_task_memory_unchanged(task_memory) do 
    assert UserTask.get(task_memory.task_id) == task_memory
  end
end
  
