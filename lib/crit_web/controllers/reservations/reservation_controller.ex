defmodule CritWeb.Reservations.ReservationController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reservation_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.ViewModels.Reservation
  alias Crit.Reservations.{ReservationApi}
  alias CritWeb.Controller.Common
  
  plug :must_be_able_to, :make_reservations

  def _show(conn, %{"reservation_id" => id}) do
    reservation = ReservationApi.get!(id, institution(conn))
    view_model = Reservation.Show.to_view_model(reservation, institution(conn))

    Common.render_for_replacement(conn,
      "_show_one_reservation.html",
      reservation: view_model)
  end
end
