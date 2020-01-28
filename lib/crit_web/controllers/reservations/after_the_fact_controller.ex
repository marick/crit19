defmodule CritWeb.Reservations.AfterTheFactController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :after_the_fact_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.Reservations.AfterTheFact.{StartData}
  alias Crit.Setup.{InstitutionApi,AnimalApi}

  plug :must_be_able_to, :make_reservations

  def start(conn, _params) do
    render(conn, "species_and_time_form.html",
      changeset: StartData.empty,
      path: path(:put_species_and_time),
      species_options: InstitutionApi.available_species(institution(conn)),
      time_slot_options: InstitutionApi.time_slot_tuples(institution(conn)))
  end

  def put_species_and_time(conn, %{"start_data" => params}) do
    IO.inspect params
    changeset = 
      params
      |> Map.put("institution", institution(conn))
      |> StartData.changeset

    animals =
      AnimalApi.available_after_the_fact(changeset.changes, @institution)

    render(conn, "animals_form.html",
      changeset: changeset,
      path: path(:put_animals),
      animals: animals)

  end

  def put_animals(conn, %{"after_the_fact_form" => _params}) do
    render(conn, "procedures_form.html",
      path: path(:put_procedures))
  end
  
  def put_procedures(conn, %{"after_the_fact_form" => _params}) do
    render(conn, "done.html")
  end
  
end
