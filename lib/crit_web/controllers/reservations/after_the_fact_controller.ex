defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.{InstitutionApi,AnimalApi, ProcedureApi}
  alias Crit.State.UserTask
  alias CritWeb.Reservations.AfterTheFactStructs.TaskMemory
  alias CritWeb.Reservations.AfterTheFactStructs.ActionData
  alias CritWeb.Reservations.AfterTheFactView, as: View
  alias Crit.Reservations.ReservationApi
  alias CritWeb.Reservations.ReservationController

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    task_memory = UserTask.start(TaskMemory)

    start_task_render(conn, task_memory, ActionData.NonUseValues.empty)
  end

  defp start_task_render(conn, task_memory, changeset) do
    task_render(conn, :put_non_use_values, task_memory,
      changeset: changeset,
      species_options: InstitutionApi.species(institution(conn)) |> EnumX.id_pairs(:name),
      timeslot_options: InstitutionApi.timeslots(institution(conn)) |> EnumX.id_pairs(:name))
  end

  def put_non_use_values(conn, %{"non_use_values" => delivered_params}) do
    # Institution is needed for time calculations
    params = Map.put(delivered_params, "institution", institution(conn))
    case UserTask.pour_into_struct(params, ActionData.NonUseValues) do
      {:ok, action_data, _task_id} ->
        header =
          View.non_use_values_header(
            action_data.date_showable_date,
            InstitutionApi.timeslot_name(action_data.timeslot_id, institution(conn)))

        task_memory = UserTask.remember_relevant(action_data, task_header: header)
        task_render(conn, :put_animals, task_memory)
      {:error, changeset, task_id} ->
        start_task_render(conn, UserTask.get(task_id), changeset)
    end
  end

  def put_animals(conn, %{"animals" => params}) do
    case UserTask.pour_into_struct(params, ActionData.Animals) do
      {:ok, action_data, _task_id} ->
        header =
          action_data.chosen_animal_ids
          |> AnimalApi.ids_to_animals(institution(conn))
          |> View.animals_header

        task_memory = UserTask.remember_relevant(action_data, task_header: header)
    
        task_render(conn, :put_procedures, task_memory)

      {:task_expiry, message} ->
        task_expiry_error(conn, message, path(:start))

      {:error, _changeset, task_id} ->
        conn
        |> selection_list_error("animal")
        |> task_render(:put_animals, UserTask.get(task_id))
    end
  end
  
  def put_procedures(conn, %{"procedures" => params}) do
    case UserTask.pour_into_struct(params, ActionData.Procedures) do
      {:ok, action_data, task_id} ->
        chosen_procedures =
          ProcedureApi.all_by_ids(action_data.chosen_procedure_ids,
            institution(conn),
            preload: [:frequency])

        task_memory = UserTask.remember_relevant(action_data, chosen_procedures: chosen_procedures)
        
        {:ok, reservation, conflicts} =
          ReservationApi.create_noting_conflicts(task_memory, institution(conn))
        UserTask.delete(task_id)

        conn
        |> put_flash(:info, View.describe_creation(conflicts))
        |> redirect(to: ReservationController.path(:show, reservation))

      {:task_expiry, message} ->
        task_expiry_error(conn, message, path(:start))

      {:error, _changeset, task_id} ->
        conn
        |> selection_list_error("procedure")
        |> task_render(:put_procedures, UserTask.get(task_id))
    end
  end

  # ----------------------------------------------------------------------------

  defp task_expiry_error(conn, message, start_again) do 
    conn
    |> put_flash(:error, message)
    |> redirect(to: start_again)
  end

  defp selection_list_error(conn, list_element_type) do
    conn
    |> put_flash(:error, "You have to select at least one #{list_element_type}")
  end

  defp task_render(conn, :put_animals, task_memory) do
    animals =
      ReservationApi.after_the_fact_animals(task_memory, institution(conn))
    
    task_render(conn, :put_animals, task_memory, animals: animals)
  end

  defp task_render(conn, :put_procedures, task_memory) do
    procedures =
      ProcedureApi.all_by_species(task_memory.species_id, institution(conn))
    task_render(conn, :put_procedures, task_memory, procedures: procedures)
  end

  defp task_render(conn, next_action, task_memory, opts) do
    html = to_string(next_action) <> ".html"
    all_opts = opts ++ [path: path(next_action), state: task_memory]
    render(conn, html, all_opts)
  end
end
