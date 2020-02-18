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
  alias Crit.Reservations.Schemas.Reservation

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    render(conn, "species_and_time_form.html",
      changeset: Scratch.SpeciesAndTime.empty,
      path: path(:put_species_and_time),
      species_options: InstitutionApi.available_species(institution(conn)),
      time_slot_options: InstitutionApi.time_slot_tuples(institution(conn)))
  end

  def put_species_and_time(conn, %{"species_and_time" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))

    case ChangesetX.realize_struct(params, Scratch.SpeciesAndTime) do
      {:ok, new_data} ->
        header =
          View.species_and_time_header(
            new_data.date_showable_date,
            InstitutionApi.time_slot_name(new_data.time_slot_id, institution(conn)))

        state =
          UserTask.start(Scratch.State, new_data, species_and_time_header: header)
        animals =
          AnimalApi.available_after_the_fact(new_data, @institution)

        task_render(conn, :put_animals, state, animals: animals)
    end
  end

  def put_animals(conn, %{"animals" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))

    case ChangesetX.realize_struct(params, Scratch.Animals) do
      {:ok, new_data} ->
        header =
          new_data.chosen_animal_ids
          |> AnimalApi.ids_to_animals(new_data.institution)
          |> View.animals_header

        state = UserTask.store(new_data, animals_header: header)

        procedures =
          ProcedureApi.all_by_species(state.species_id, new_data.institution)
        
        render(conn, "procedures_form.html",
          procedures: procedures,
          task_id: state.task_id,
          path: path(:put_procedures),
          header: [state.species_and_time_header, header]
        )
    end
  end
  
  def put_procedures(conn, %{"procedures" => delivered_params}) do
    params = Map.put(delivered_params, "institution", institution(conn))
    case ChangesetX.realize_struct(params, Scratch.Procedures) do
      {:ok, new_data} ->

        state = UserTask.store(new_data)

        {:ok, reservation} = Reservation.create(state, institution(conn))

        render(conn, "done.html", show: inspect(reservation))
    end
  end

  # Helpers

  def task_render(conn, next_action, state, opts \\ []) do
    html = to_string(next_action) <> ".html"
    all_opts = opts ++ [path: path(next_action), state: state]
    render(conn, html, all_opts)
  end
  
end
