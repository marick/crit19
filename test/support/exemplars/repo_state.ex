defmodule Crit.Exemplars.RepoState do
  use Crit.TestConstants
  import Crit.RepoState
  alias Ecto.Datespan

  def repo_has_bossie do 
    span = Datespan.customary(@earliest_date, @latest_date)
    empty_repo(@bovine_id)
    |> animal("Bossie", available_on: span)
    |> shorthand
  end

  def repo_has_bossie(_), do: [repo: repo_has_bossie()]
end
