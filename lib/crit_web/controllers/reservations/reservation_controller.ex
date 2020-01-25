defmodule CritWeb.Reservations.ReservationController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reservation_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.Reservations.AfterTheFactForm
  alias Crit.Setup.InstitutionApi

  plug :must_be_able_to, :make_reservations

  def after_the_fact_form_1(conn, _params) do
    render(conn, "after_the_fact_form_1.html",
      changeset: AfterTheFactForm.changeset_1,
      path: path(:after_the_fact_record_1),
      species_options: InstitutionApi.available_species(institution(conn)),
      time_slot_options: InstitutionApi.time_slot_tuples(institution(conn)))
  end

  def after_the_fact_record_1(conn, %{"after_the_fact_form" => params}) do
    IO.inspect params
    render(conn, "after_the_fact_form_2.html")
  end
end
