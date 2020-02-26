defmodule CritWeb.Reservations.ReservationController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reservation_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.ViewModels.Reservation
  alias Crit.Reservations.{ReservationApi}
  alias CritWeb.Controller.Common
  
  plug :must_be_able_to, :make_reservations

  def show(conn, %{"reservation_id" => id}) do
    view_model =
      id
      |> ReservationApi.get!(institution(conn))
      |> Reservation.Show.to_view_model(institution(conn))

    render(conn, "show.html", reservation: view_model)
  end

  def by_animal_form(conn, _params) do
    render(conn, "by_animal_form.html",
      path: path(:by_animal)
    )
  end

  def by_animal(conn, %{"animal" => %{"date" => date}}) do
    conn
  end
  
end
