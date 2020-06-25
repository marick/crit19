defmodule Crit.Exemplars.Bossie do
  use Crit.TestConstants
  use ExContract
  import Crit.RepoState
  alias CritWeb.ViewModels.Setup, as: VM
  import Crit.Assertions.Map
  alias Crit.Exemplars, as: Ex
  alias Crit.Factory

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

  def put_service_gap(repo, opts) do
    opts = Enum.into(opts, %{name: Factory.unique(:service_gap)})
    check Map.has_key?(opts, :span)
    
    starting = Ex.Datespan.in_service(opts.span)
    ending = Ex.Datespan.out_of_service(opts.span)
    repo 
    |> service_gap_for("Bossie", name: opts.name, starting: starting, ending: ending)
    |> shorthand
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
end
