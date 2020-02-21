defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.{InstitutionApi,AnimalApi, ProcedureApi}
  # alias Ecto.Changeset
  alias Ecto.ChangesetX
  alias Crit.State.UserTask
  alias CritWeb.Reservations.AfterTheFactStructs, as: Scratch
  alias CritWeb.Reservations.AfterTheFactView, as: View
  alias Crit.Reservations.ReservationApi

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    render(conn, "species_and_time_form.html",
      changeset: Scratch.SpeciesAndTime.empty,
      path: path(:put_species_and_time),
      species_options: InstitutionApi.available_species(institution(conn)),
      timeslot_options: InstitutionApi.timeslot_tuples(institution(conn)))
  end

  def put_species_and_time(conn, %{"species_and_time" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))

    case ChangesetX.realize_struct(params, Scratch.SpeciesAndTime) do
      {:ok, new_data} ->
        header =
          View.species_and_time_header(
            new_data.date_showable_date,
            InstitutionApi.timeslot_name(new_data.timeslot_id, institution(conn)))

        state =
          UserTask.start(Scratch.State, new_data, task_header: header)
        task_render(conn, :put_animals, state)
    end
  end

  def put_animals(conn, %{"animals" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))

    case ChangesetX.realize_struct(params, Scratch.Animals) do
      {:ok, new_data} ->
        header =
          new_data.chosen_animal_ids
          |> AnimalApi.ids_to_animals(institution(conn))
          |> View.animals_header

        state = UserTask.store(new_data, task_header: header)

        procedures =
          ProcedureApi.all_by_species(state.species_id, institution(conn))

        task_render(conn, :put_procedures, state, procedures: procedures)
      {:error, changeset} -> # There's only one error.
        conn
        |> selection_list_error("animal")
        |> task_render(:put_animals, UserTask.get(changeset.changes.task_id))
    end
  end
  
  def put_procedures(conn, %{"procedures" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))
    case ChangesetX.realize_struct(params, Scratch.Procedures) do
      {:ok, new_data} ->
        state = UserTask.store(new_data)
        {:ok, reservation} = ReservationApi.create(state, institution(conn))
        UserTask.delete(state.task_id)
        render(conn, "done.html", reservation: reservation)
    end
  end

  # Helpers

  def selection_list_error(conn, what) do
    put_flash(conn, :error, "You have to select at least one #{what}")
  end

  defp task_render(conn, :put_animals, state) do
    IO.inspect state
    animals =
      AnimalApi.available_after_the_fact(state, institution(conn))
    
    task_render(conn, :put_animals, state, animals: animals)
  end

  defp task_render(conn, next_action, state, opts) do
    html = to_string(next_action) <> ".html"
    all_opts = opts ++ [path: path(next_action), state: state]
    render(conn, html, all_opts)
  end
end
