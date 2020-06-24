defmodule Crit.Exemplars.Bossie do
  use Crit.TestConstants
  import Crit.RepoState
  alias Ecto.Datespan
  alias CritWeb.ViewModels.Setup, as: VM
  import Crit.Assertions.Map

  def maximum_customary_span do
    Datespan.customary(@earliest_date, @latest_date)    
  end

  def repo_has_bossie do 
    empty_repo(@bovine_id)
    |> animal("Bossie", available: maximum_customary_span())
    |> shorthand
  end

  def repo_has_bossie(_), do: [repo: repo_has_bossie()]


  def assert_bossie(%VM.Animal{} = animal, id) do
    animal
    |> assert_fields(id: id,
                     lock_version: 1,
                     name: "Bossie",
                     species_name: @bovine,
                     institution: @institution,
                     in_service_datestring: @earliest_iso_date,
                     out_of_service_datestring: @latest_iso_date)
  end
end
