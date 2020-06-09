defmodule CritWeb.ViewModels.FieldFillers.FromWeb do
  use Crit.Global.Constants
  alias Ecto.Datespan
  alias Crit.Setup.InstitutionApi
  alias Pile.TimeHelper

  def span(data) do
    today = fn ->
      data.institution |> InstitutionApi.timezone |> TimeHelper.today_date
    end

    date = fn string -> Date.from_iso8601!(string) end

    case {data.in_service_datestring, data.out_of_service_datestring} do
      {@today, @never} ->
        Datespan.inclusive_up(today.())
      {first, @never} ->
        Datespan.inclusive_up(date.(first))
      {@today, last} ->
        Datespan.customary(today.(), date.(last))
      {first, last} ->
        Datespan.customary(date.(first), date.(last))
    end
  end
end
