defmodule CritWeb.Reservations.ReservationController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reservation_path
  import CritWeb.Plugs.Authorize
  alias CritWeb.ViewModels.Reservation
  alias Crit.Reservations.{ReservationApi}
  alias CritWeb.ViewModels.DateOrDates
  alias Pile.TimeHelper
  alias Crit.Setup.InstitutionApi
  
  plug :must_be_able_to, :make_reservations

  def show(conn, %{"reservation_id" => id}) do
    view_model =
      id
      |> ReservationApi.get!(institution(conn))
      |> Reservation.Show.to_view_model(institution(conn))

    render(conn, "show.html", reservation: view_model)
  end

  def by_dates_form(conn, _params) do
    render(conn, "by_dates_form.html",
      changeset: DateOrDates.starting_changeset(),
      path: path(:by_dates)
    )
  end

  def by_dates(conn, %{"date_or_dates" => params}) do
    {:ok, first_date, last_date} = DateOrDates.to_dates(params, institution(conn))
    reservations =
      ReservationApi.on_dates(first_date, last_date, institution(conn))
      |> Enum.map(&(Reservation.Show.to_view_model(&1, institution(conn))))

    render(conn, "by_dates.html",
      first_date: first_date,
      last_date: last_date,
      reservations: reservations
    )
  end

  def weekly_calendar(conn, _params) do
    render(conn, "weekly.html")
  end

  def week_data(conn, %{"week_offset" => count_string}) do
    count = String.to_integer(count_string)
    central_date = Date.add(InstitutionApi.today!(institution(conn)), count * 7)
    {sunday, saturday} = TimeHelper.week_dates(central_date)

    reservations =
      ReservationApi.on_dates(sunday, saturday, institution(conn))
    render(conn, "week.json", %{reservations: reservations,
                               institution: institution(conn)})
  end
end
