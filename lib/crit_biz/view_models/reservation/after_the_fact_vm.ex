defmodule CritBiz.ViewModels.Reservation.AfterTheFact do
  alias Crit.Servers.UserTask
  alias CritBiz.ViewModels.Reservation.AfterTheFact.Forms
  alias Ecto.Changeset
  alias Crit.Servers.Institution
  alias Crit.Reservations.ReservationApi
  alias CritBiz.ViewModels.Step

  defstruct task_id: :nothing,
    # Values needed for creation
    
    species_id:           :nothing,
    date:                 :nothing,
    timeslot_id:          :nothing,
    span:                 :nothing,
    responsible_person:   :nothing,
    
    chosen_animal_ids:    :nothing,
    chosen_procedure_ids: :nothing,


  # For the non-field parts of the display.
    ## Values needed after step 1 (Start)
    institution:          :nothing,
  
  ## Values needed after step 2 (put context)
    task_header:          :nothing
  
  ## Values needed after step 3 (put animals)
  
  ## Values needed after step 3 (put procedures)


  
  def start(institution) do
    task_memory = UserTask.start(__MODULE__, institution: institution)
    changeset = Forms.Context.empty
    {task_memory, changeset}
  end



  def accept_context_form(params) do
    Step.attempt_step(params, Forms.Context,
      next_task_memory: &Forms.Context.next_task_memory/2, 
      next_form_data: &Forms.Context.next_form_data/2)
  end
    
  #   changeset = apply(struct_module, :changeset, [params])
  #     task_id = Changeset.fetch_change!(changeset, :task_id)
  #     changeset
  #     |> Changeset.apply_action(:insert)
  #     |> Tuple.append(task_id)
  #   end
    



  # def put_context(conn, %{"context" => delivered_params}) do
  #   # Institution is needed for time calculations
  #   params = Map.put(delivered_params, "institution", institution(conn))
  #   case UserTask.pour_into_struct(params, VM.Forms.Context) do
  #     {:ok, struct, _task_id} -> got_valid_context(conn, struct)
  #     {:error, changeset, task_id} ->
  #       render_start_of_task__2(conn, {UserTask.get(task_id), changeset})
  #   end
  # end

  # defp got_valid_context(conn, %VM.Forms.Context{} = struct) do
  #   header =
  #     View.context_header(
  #       struct.date_showable_date,
  #       Institution.timeslot_name(struct.timeslot_id, institution(conn)))

  #   task_memory = UserTask.remember_relevant(struct, task_header: header)
  #   render_form_for_animals_step(conn, :put_animals, task_memory)
  # end

  # defp render_form_for_animals_step(conn, :put_animals, task_memory) do
  #   animals =
  #     ReservationApi.after_the_fact_animals(task_memory, institution(conn))
    
  #   render_form_for_next_step(conn, :put_animals, task_memory, animals: animals)
  # end
    
end
