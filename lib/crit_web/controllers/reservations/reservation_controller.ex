defmodule CritWeb.Reservations.ReservationController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reservation_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.Reservations.ReservationForm
  alias Crit.Setup.InstitutionApi

  plug :must_be_able_to, :make_reservations

  def backdated_form(conn, _params) do
    _changeset = ReservationForm.initial
    render(conn, "backdated.html",
      changeset: ReservationForm.initial,
      path: path(:record_step_1),
      options: InstitutionApi.available_species(institution(conn)))
  end
end
