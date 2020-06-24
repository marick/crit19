defmodule CritWeb.ViewModels.Setup.AnimalVM.FromRepoTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.AnimalApi2, as: AnimalApi
  import Crit.Exemplars.Bossie, only: [repo_has_bossie: 1]
  alias Crit.Exemplars, as: Ex

  setup :repo_has_bossie

  # These tests are all about proceding VM.Animal structs

  # ----------------------------------------------------------------------------

  describe "lift" do
    test "a lifting without service gaps)", %{repo: repo} do
      repo.bossie.id
      |> AnimalApi.one_by_id(@institution, preload: [:species])
      |> VM.Animal.lift(@institution)
      |> Ex.Bossie.assert_view_model_for(id: repo.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "lifting with service gaps", %{repo: repo} do
      Ex.Bossie.put_service_gap(repo, span: :first)

      repo.bossie.id
      |> AnimalApi.one_by_id(@institution, preload: [:species, :service_gaps])
      |> VM.Animal.lift(@institution)
      
      |> Ex.Bossie.assert_view_model_for(id: repo.bossie.id)
      |> using_singleton_in(:service_gaps, fn sg ->
           sg
           |> assert_shape(%VM.ServiceGap{})      
           |> Ex.Datespan.assert_datestrings(:first)
         end)
    end
  end

  # ----------------------------------------------------------------------------
  describe "`fetch` from database" do 
    test "fetching a list of animals does not produce service gaps",
      %{repo: repo} do
      
      VM.Animal.fetch(:all_possible, @institution)
      |> singleton_payload
      |> Ex.Bossie.assert_view_model_for(id: repo.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for a summary does not produce a service gap",
      %{repo: repo} do 

      VM.Animal.fetch(:one_for_summary, repo.bossie.id, @institution)
      |> Ex.Bossie.assert_view_model_for(id: repo.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for editing does include service gaps",
      %{repo: repo} do 

      VM.Animal.fetch(:one_for_edit, repo.bossie.id, @institution)
      |> Ex.Bossie.assert_view_model_for(id: repo.bossie.id)
      |> assert_assoc_loaded(:service_gaps)
    end
  end
end
