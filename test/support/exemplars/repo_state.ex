defmodule Crit.Exemplars.RepoState do
  use Crit.TestConstants
  import Crit.RepoState
  alias Ecto.Datespan

  def maximum_customary_span do
    span = Datespan.customary(@earliest_date, @latest_date)    
  end

  def repo_has_bossie do 
    empty_repo(@bovine_id)
    |> animal("Bossie", available: maximum_customary_span)
    |> shorthand
  end

  def repo_has_bossie(_), do: [repo: repo_has_bossie()]
end
