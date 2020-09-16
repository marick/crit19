defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias Crit.Servers.Institution
  alias Crit.Schemas
  alias Crit.Servers.UserTask
  alias CritBiz.ViewModels.Reservation.AfterTheFact, as: VM
  alias CritWeb.Reservations.AfterTheFactView, as: View
  alias Crit.Reservations.ReservationApi
  alias CritWeb.Reservations.ReservationController

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    render_start_of_task__2(conn, VM.start(institution(conn)))
  end

  defp render_start_of_task__2(conn, {task_memory, changeset}) do
    render_form_for_next_step(conn, :put_context, task_memory, changeset: changeset)
  end

  # ----------------------------------------------------------------------------

  def put_context(conn, %{"context" => delivered_params}) do
    # Institution is needed for time calculations
    params = Map.put(delivered_params, "institution", institution(conn))
    case UserTask.pour_into_struct(params, VM.Forms.Context) do
      {:ok, struct, _task_id} -> got_valid_context(conn, struct)
      {:error, changeset, task_id} ->
        render_start_of_task__2(conn, {UserTask.get(task_id), changeset})
    end
  end

  defp got_valid_context(conn, %VM.Forms.Context{} = struct) do
    header =
      View.context_header(
        struct.date_showable_date,
        Institution.timeslot_name(struct.timeslot_id, institution(conn)))

    task_memory = UserTask.remember_relevant(struct, task_header: header)
    render_form_for_animals_step(conn, :put_animals, task_memory)
  end

  defp render_form_for_animals_step(conn, :put_animals, task_memory) do
    animals =
      ReservationApi.after_the_fact_animals(task_memory, institution(conn))
    
    render_form_for_next_step(conn, :put_animals, task_memory, animals: animals)
  end

  # ----------------------------------------------------------------------------


  def put_animals(conn, %{"animals" => params}) do
    case UserTask.pour_into_struct(params, VM.Forms.Animals) do
      {:ok, struct, _task_id} -> got_valid_animals(conn, struct)

      {:task_expiry, message} ->
        task_expiry_error(conn, message, path(:start))

      {:error, _changeset, task_id} ->
        conn
        |> selection_list_error("animal")
        |> render_form_for_animals_step(:put_animals, UserTask.get(task_id))
    end
  end

  defp got_valid_animals(conn, %VM.Forms.Animals{} = struct) do
    header =
      struct.chosen_animal_ids
      |> Schemas.Animal.Get.all_by_ids(institution(conn))
      |> View.animals_header
    
    task_memory = UserTask.remember_relevant(struct, task_header: header)
    
    render_form_for_procedures_step(conn, :put_procedures, task_memory)
  end

  defp render_form_for_procedures_step(conn, :put_procedures, task_memory) do
    procedures =
      Schemas.Procedure.Get.all_by_species(task_memory.species_id, institution(conn))
    render_form_for_next_step(conn, :put_procedures, task_memory, procedures: procedures)
  end
  

  # ----------------------------------------------------------------------------
  
  def put_procedures(conn, %{"procedures" => params}) do
    case UserTask.pour_into_struct(params, VM.Forms.Procedures) do
      {:ok, struct, _task_id} -> got_valid_procedures(conn, struct)

      {:task_expiry, message} ->
        task_expiry_error(conn, message, path(:start))

      {:error, _changeset, task_id} ->
        conn
        |> selection_list_error("procedure")
        |> render_form_for_procedures_step(:put_procedures, UserTask.get(task_id))
    end
  end

  defp got_valid_procedures(conn, %VM.Forms.Procedures{} = struct) do
        task_memory = UserTask.remember_relevant(struct)
        
    {:ok, reservation, conflicts} =
       ReservationApi.create_noting_conflicts(task_memory, institution(conn))
    UserTask.delete(struct.task_id)

    conn
    |> put_flash(:info, View.describe_creation(conflicts))
    |> redirect(to: ReservationController.path(:show, reservation))
  end    
  # ----------------------------------------------------------------------------



  defp render_form_for_next_step(conn, next_action, task_memory, opts) do
    html = to_string(next_action) <> ".html"
    all_opts = opts ++ [path: path(next_action), state: task_memory]
    render(conn, html, all_opts)
  end






  defp task_expiry_error(conn, message, start_again) do 
    conn
    |> put_flash(:error, message)
    |> redirect(to: start_again)
  end

  defp selection_list_error(conn, list_element_type) do
    conn
    |> put_flash(:error, "You have to select at least one #{list_element_type}")
  end

  
end

