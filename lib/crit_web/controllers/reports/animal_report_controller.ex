defmodule CritWeb.Reports.AnimalReportController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reports_animal_report_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.InstitutionApi
  alias Ecto.Timespan
  alias Crit.SqlRows.Reservation
  alias CritWeb.ViewModels.Reports.Animal

  IO.puts "need to create new permissions"
  plug :must_be_able_to, :make_reservations


  def use_form(conn, _params) do
    render(conn, "use_form.html", path: path(:use_last_month))
  end

  def use_last_month(conn, _params) do
    institution = institution(conn)
    {:ok, relevant_span} = last_month_span(institution)
    uses = 
      relevant_span
      |> Reservation.timespan_uses(institution)
      |> Animal.multi_animal_uses
    render(conn, "use.html", uses: uses)
  end

  defp last_month_span(institution) do 
    {now_year, now_month, _day} =
      InstitutionApi.today!(institution)
      |> Date.to_erl

    {year, month, _day} = 
      {now_year, now_month, 1}
      |> Date.from_erl!
      |> Date.add(-1)
      |> Date.to_erl

    Timespan.month_span(year, month)
  end
    
end
