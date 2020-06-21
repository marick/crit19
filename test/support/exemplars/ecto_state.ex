defmodule Crit.Exemplars.EctoState do
  use Crit.TestConstants
  import Crit.EctoState
  alias Ecto.Datespan

  def ecto_has_bossie do 
    span = Datespan.customary(@earliest_date, @latest_date)
    empty_ecto(@bovine_id)
    |> animal("Bossie", available_on: span)
    |> shorthand
  end

  def ecto_has_bossie(_), do: [ecto: ecto_has_bossie()]
end
