defmodule Crit.Exemplars.Bossie do
  use Crit.TestConstants
  import Crit.RepoState
  alias CritWeb.ViewModels.Setup, as: VM
  import Crit.Assertions.{Map,Misc}
  alias Crit.Exemplars, as: Ex

  @bossie "Bossie"


  # ----------setup---------------------------------------------------------------
  
  def repo_has_bossie(_), do: [repo: create()]


  # ----------------------------------------------------------------------------

  def put(repo) do
    repo
    |> animal(@bossie, available: Ex.Datespan.named(:widest_finite))
    |> shorthand
  end

  def create do 
    empty_repo(@bovine_id) |> put
  end

  def put_service_gap(repo, [span: description]) do
    starting = Ex.Datespan.in_service(description)
    ending = Ex.Datespan.out_of_service(description)
    service_gap_for(repo, "Bossie", starting: starting, ending: ending)
  end

  # ----------------------------------------------------------------------------

  def assert_view_model_for(%VM.Animal{} = animal, [id: id]) do
    animal
    |> assert_fields(id: id,
                     lock_version: 1,
                     name: @bossie,
                     species_name: @bovine,
                     institution: @institution,
                     in_service_datestring: @earliest_iso_date,
                     out_of_service_datestring: @latest_iso_date)
  end

  def with_only_service_gap(animal, f) do
    animal.service_gaps
    |> singleton_payload
    |> f.()
  end
end
