defmodule CritBiz.ViewModels.FieldFillers.FromWeb do
  use Crit.Global.Constants
  alias Ecto.Datespan
  alias Crit.Servers.Institution
  alias Ecto.Changeset

  def span(%Changeset{} = changeset),
    do: changeset |> Changeset.apply_changes |> span
  
  def span(%{} = data) do
    date = fn string -> Date.from_iso8601!(string) end
    today = fn -> Institution.today!(data.institution) end

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
