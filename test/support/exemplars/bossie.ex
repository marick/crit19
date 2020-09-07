defmodule Crit.Exemplars.Bossie do
  use Crit.TestConstants
  use ExContract
  import Crit.RepoState
  alias CritBiz.ViewModels.Setup, as: VM
  import FlowAssertions.MapA
  alias Crit.Exemplars, as: Ex
  alias Crit.Factory

  @bossie "Bossie"


  # ----------setup---------------------------------------------------------------
  
  def repo_has_bossie(_), do: [repo: create()]

  def bossie_has_service_gap(%{repo: repo}),
    do: Ex.Bossie.put_service_gap(repo, span: :first)

  # ----------------------------------------------------------------------------

  def put(repo) do
    repo
    |> animal(@bossie, available: Ex.Datespan.named(:widest_finite))
  end

  def create do 
    empty_repo(@bovine_id) |> put
  end

  def put_service_gap(repo, opts \\ []) do
    opts = Enum.into(opts, %{
          name: Factory.unique(:service_gap),
          reason: Factory.unique(:reason),
          span: :first})
    
    starting = Ex.Datespan.in_service(opts.span)
    ending = Ex.Datespan.out_of_service(opts.span)
    opts = [name: opts.name, reason: opts.reason, starting: starting, ending: ending]
    repo 
    |> service_gap_for("Bossie", opts)
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
