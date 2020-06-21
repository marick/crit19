defmodule Crit.Exemplars.Background do
  use Crit.TestConstants
  import Crit.Background
  alias Ecto.Datespan

  def background_bossie do 
    span = Datespan.customary(@earliest_date, @latest_date)
    background(@bovine_id)
    |> animal("Bossie", available_on: span)
    |> shorthand
  end

  def background_bossie(_), do: [background: background_bossie()]
end
