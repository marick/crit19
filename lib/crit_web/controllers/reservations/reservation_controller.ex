defmodule CritWeb.Reservations.ReservationController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reservation_path
  import CritWeb.Plugs.Authorize

  plug :must_be_able_to, :make_reservations

  def backdated_form(conn, _params) do
    render(conn, "backdated.html")
  end
end
