defmodule CritWeb.Reservations.ReservationController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reservation_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.ViewModels.Reservation
  alias Crit.Reservations.{ReservationApi}
  alias CritWeb.Controller.Common
  
  plug :must_be_able_to, :make_reservations

  def _show(conn, %{"reservation_id" => id}) do
    view_model =
      id
      |> ReservationApi.get!(institution(conn))
      |> Reservation.Show.to_view_model(institution(conn))

    render(conn, "show.html", reservation: view_model)
  end
end
