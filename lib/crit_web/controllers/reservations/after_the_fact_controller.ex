defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.{InstitutionApi,AnimalApi, ProcedureApi}
  alias Crit.State.UserTask
  alias CritWeb.Reservations.AfterTheFactStructs.TaskMemory
  alias CritWeb.Reservations.AfterTheFactStructs.Transient
  alias CritWeb.Reservations.AfterTheFactView, as: View
  alias Crit.Reservations.ReservationApi
  alias CritWeb.Reservations.ReservationController
  alias Ecto.Changeset

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    state = UserTask.start(TaskMemory)

    start_task_render(conn, state, Transient.NonUseValues.empty)
  end

  defp start_task_render(conn, state, changeset) do
    task_render(conn, :put_non_use_values, state,
      changeset: changeset,
      species_options: InstitutionApi.species(institution(conn)) |> EnumX.id_pairs(:name),
      timeslot_options: InstitutionApi.timeslots(institution(conn)) |> EnumX.id_pairs(:name))
  end

  def put_non_use_values(conn, %{"non_use_values" => delivered_params}) do
    # Institution is needed for time calculations
    params = Map.put(delivered_params, "institution", institution(conn))
    case UserTask.pour_into_struct(params, Transient.NonUseValues) do
      {:ok, new_data} ->
        header =
          View.non_use_values_header(
            new_data.date_showable_date,
            InstitutionApi.timeslot_name(new_data.timeslot_id, institution(conn)))

        state = UserTask.remember_relevant(new_data, task_header: header)
        task_render(conn, :put_animals, state)
      {:error, changeset} ->
        task_id = Map.get(params, "task_id")
        start_task_render(conn, UserTask.get(task_id), changeset)
    end
  end

  def put_animals(conn, %{"animals" => params}) do
    case UserTask.pour_into_struct(params, Transient.Animals) do
      {:ok, new_data} ->
        header =
          new_data.chosen_animal_ids
          |> AnimalApi.ids_to_animals(institution(conn))
          |> View.animals_header

        state = UserTask.remember_relevant(new_data, task_header: header)
        task_render(conn, :put_procedures, state)

      {:task_expiry, message} ->
        task_expiry_error(conn, message, path(:start))

      {:error, changeset} -> 
        selection_list_error(conn, changeset, :put_animals, "animal")
    end
  end
  
  def put_procedures(conn, %{"procedures" => params}) do
    case UserTask.pour_into_struct(params, Transient.Procedures) do
      {:ok, new_data} ->
        state = UserTask.remember_relevant(new_data)
        {:ok, reservation, conflicts} =
          ReservationApi.create_noting_conflicts(state, institution(conn))
        UserTask.delete(state.task_id)

        conn
        |> put_flash(:info, View.describe_creation(conflicts))
        |> redirect(to: ReservationController.path(:show, reservation))

      {:task_expiry, message} ->
        task_expiry_error(conn, message, path(:start))

      {:error, changeset} ->
        selection_list_error(conn, changeset, :put_procedures, "procedure")
    end
  end

  # ----------------------------------------------------------------------------

  defp task_expiry_error(conn, message, start_again) do 
    conn
    |> put_flash(:error, message)
    |> redirect(to: start_again)
  end

  defp selection_list_error(conn, changeset, action_to_retry, list_element_type) do
    task_id = Changeset.fetch_change!(changeset, :task_id)
    conn
    |> put_flash(:error, "You have to select at least one #{list_element_type}")
    |> task_render(action_to_retry, UserTask.get(task_id))
  end

  defp task_render(conn, :put_animals, state) do
    animals =
      ReservationApi.after_the_fact_animals(state, institution(conn))
    
    task_render(conn, :put_animals, state, animals: animals)
  end

  defp task_render(conn, :put_procedures, state) do
    procedures =
      ProcedureApi.all_by_species(state.species_id, institution(conn))
    
    task_render(conn, :put_procedures, state, procedures: procedures)
  end

  defp task_render(conn, next_action, state, opts) do
    html = to_string(next_action) <> ".html"
    all_opts = opts ++ [path: path(next_action), state: state]
    render(conn, html, all_opts)
  end
end
