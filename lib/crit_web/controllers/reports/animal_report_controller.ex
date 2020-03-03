defmodule CritWeb.Reports.AnimalReportController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :reports_animal_report_path
  import CritWeb.Plugs.Authorize
#  alias Crit.Setup.InstitutionApi

  IO.puts "need to create new permissions"
  plug :must_be_able_to, :view_reservations


  def use_form(conn, _params) do
    render(conn, "use_form.html", path: path(:use))
  end

  def use_last_month(conn, _params) do
    render(conn, "use.html")
  end
    
end
