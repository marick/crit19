defmodule CritBiz.ViewModels.Reservation.AfterTheFact do
  alias Crit.Servers.UserTask
  alias CritBiz.ViewModels.Reservation.AfterTheFact.Forms
  alias Ecto.{Changeset,ChangesetX}
  alias Crit.Servers.Institution

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


  defp attempt_step(params, form_module, next_task_memory: next_task_memory) do
    UserTask.supplying_task_memory(params, fn task_memory ->
      changeset = form_module.changeset(params)
      case changeset.valid? do
        false ->
          {:error, :form, changeset}
        true ->
          {:ok, struct} = Changeset.apply_action(changeset, :insert)
          new_task_memory = next_task_memory.(task_memory, struct)
          UserTask.replace(task_memory.task_id, new_task_memory)
          {:ok, new_task_memory, nil}
      end
    end)
  end

  def check_not_already_initialized(task_memory, field) do 
    case Map.get(task_memory, field) do
      :nothing ->
        :ok
      value ->
        raise "Task memory already has value `#{inspect value}` for field `#{inspect field}`"
    end
  end

  def initialize_by_transfer(task_memory, source, fields) do
    Enum.reduce(fields, task_memory, fn field, acc ->
      check_not_already_initialized(task_memory, field)
      Map.put(acc, field, Map.get(source, field))
    end)
  end

  def initialize_by_setting(task_memory, kvs) do
    Enum.reduce(kvs, task_memory, fn {field, value}, acc ->
      check_not_already_initialized(task_memory, field)
      Map.put(acc, field, value)
    end)
  end

  @context_transfers [:species_id, :responsible_person, :date, :timeslot_id]

  def accept_context_form(params) do
    attempt_step(params, Forms.Context,
      next_task_memory: fn task_memory, struct ->
        span =
          Institution.timespan(
            struct.date, struct.timeslot_id, task_memory.institution)
        
        task_memory
        |> initialize_by_transfer(struct, @context_transfers)
        |> initialize_by_setting(span: span)
      end)
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
