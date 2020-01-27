defmodule CritWeb.Reservations.ReservationController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reservation_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.Reservations.AfterTheFactForm
  alias Crit.Setup.{InstitutionApi,AnimalApi}

  plug :must_be_able_to, :make_reservations

  def after_the_fact_form_1(conn, _params) do
    render(conn, "after_the_fact_form_1.html",
      changeset: AfterTheFactForm.empty,
      path: path(:after_the_fact_record_1),
      species_options: InstitutionApi.available_species(institution(conn)),
      time_slot_options: InstitutionApi.time_slot_tuples(institution(conn)))
  end

  def after_the_fact_record_1(conn, %{"after_the_fact_form" => params}) do
    changeset = 
      params
      |> Map.put("institution", institution(conn))
      |> AfterTheFactForm.form_1_changeset

    animals =
      AnimalApi.available_after_the_fact(changeset.changes, @institution)

    render(conn, "after_the_fact_form_2.html",
      changeset: changeset,
      path: path(:after_the_fact_record_2),
      animal_options: EnumX.pairs(animals, :name, :id))

  end

  def after_the_fact_record_2(conn, %{"after_the_fact_form" => params}) do
    changeset = 
      params
      |> Map.put("institution", institution(conn))
      |> AfterTheFactForm.form_1_changeset

    render(conn, "after_the_fact_form_3.html",
      changeset: changeset,
      path: path(:after_the_fact_record_3))
  end
  
end
