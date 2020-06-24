defmodule CritWeb.ViewModels.Setup.AnimalVM.FromRepoTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.AnimalApi2, as: AnimalApi
  import Crit.Exemplars.Bossie
  import Crit.RepoState

  setup :repo_has_bossie

  # These tests are all about proceding VM.Animal structs

  # ----------------------------------------------------------------------------

  describe "lift" do
    test "a lifting without service gaps)", %{repo: repo} do
      AnimalApi.one_by_id(repo.bossie.id, @institution, preload: [:species])
      |> VM.Animal.lift(@institution)
      |> assert_bossie(repo.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "listing with service gaps", %{repo: repo} do
      service_gap_for(repo, "Bossie", starting: @date_2, ending: @date_3)
      
      fetched = 
        AnimalApi.one_by_id(repo.bossie.id, @institution,
          preload: [:species, :service_gaps])
        |> VM.Animal.lift(@institution)
        |> assert_bossie(repo.bossie.id)

      fetched.service_gaps
      |> singleton_payload
      |> assert_shape(%VM.ServiceGap{})
      |> assert_fields(in_service_datestring: @iso_date_2,
                       out_of_service_datestring: @iso_date_3)
    end
  end

  # ----------------------------------------------------------------------------
  describe "`fetch` from database" do 
    test "fetching a list of animals does not produce service gaps",
      %{repo: repo} do
      
      VM.Animal.fetch(:all_possible, @institution)
      |> singleton_payload
      |> assert_bossie(repo.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for a summary does not produce a service gap",
      %{repo: repo} do 

      VM.Animal.fetch(:one_for_summary, repo.bossie.id, @institution)
      |> assert_bossie(repo.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for editing does include service gaps",
      %{repo: repo} do 

      VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
      |> assert_bossie(repo.bossie.id)
      |> assert_assoc_loaded(:service_gaps)
    end
  end
end
