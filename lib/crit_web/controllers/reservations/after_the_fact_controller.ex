defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.{InstitutionApi,AnimalApi, ProcedureApi}
  alias Crit.State.UserTask
  alias CritWeb.Reservations.AfterTheFactStructs, as: Scratch
  alias CritWeb.Reservations.AfterTheFactView, as: View
  alias Crit.Reservations.ReservationApi
  alias Ecto.Changeset

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    state = UserTask.start(Scratch.State)

    task_render(conn, :put_species_and_time, state,
      changeset: Scratch.SpeciesAndTime.empty,
      species_options: InstitutionApi.available_species(institution(conn)),
      timeslot_options: InstitutionApi.timeslot_tuples(institution(conn)))
  end

  def put_species_and_time(conn, %{"species_and_time" => delivered_params}) do
    # Institution is needed for time calculations
    params = Map.put(delivered_params, "institution", institution(conn))
    case UserTask.pour_into_struct(params, Scratch.SpeciesAndTime) do
      {:ok, new_data} ->
        header =
          View.species_and_time_header(
            new_data.date_showable_date,
            InstitutionApi.timeslot_name(new_data.timeslot_id, institution(conn)))

        state = UserTask.store(new_data, task_header: header)
        task_render(conn, :put_animals, state)
    end
  end

  def put_animals(conn, %{"animals" => params}) do
    case UserTask.pour_into_struct(params, Scratch.Animals) do
      {:ok, new_data} ->
        header =
          new_data.chosen_animal_ids
          |> AnimalApi.ids_to_animals(institution(conn))
          |> View.animals_header

        state = UserTask.store(new_data, task_header: header)
        task_render(conn, :put_procedures, state)

      {:error, changeset} -> 
        selection_list_error(conn, changeset, :put_animals, "animal")
    end
  end
  
  def put_procedures(conn, %{"procedures" => params}) do
    case UserTask.pour_into_struct(params, Scratch.Procedures) do
      {:ok, new_data} ->
        state = UserTask.store(new_data)
        {:ok, reservation} = ReservationApi.create(state, institution(conn))
        UserTask.delete(state.task_id)
        render(conn, "done.html", reservation: reservation)

      {:error, changeset} ->
        selection_list_error(conn, changeset, :put_procedures, "procedure")
    end
  end

  # ----------------------------------------------------------------------------

  defp selection_list_error(conn, changeset, action_to_retry, list_element_type) do
    task_id = Changeset.fetch_change!(changeset, :task_id)
    case Enum.member?(Keyword.keys(changeset.errors), :task_id) do
      true ->
        conn
        |> put_flash(:error, UserTask.full_expiry_error())
        |> redirect(to: (path(:start)))
      false -> 
        conn
        |> put_flash(:error, "You have to select at least one #{list_element_type}")
        |> task_render(action_to_retry, UserTask.get(task_id))
    end
  end

  defp task_render(conn, :put_animals, state) do
    animals =
      AnimalApi.available_after_the_fact(state, institution(conn))
    
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
