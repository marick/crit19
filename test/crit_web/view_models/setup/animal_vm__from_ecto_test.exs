defmodule CritWeb.ViewModels.Setup.AnimalVM.FromEctoTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.AnimalApi2, as: AnimalApi
  import Crit.Exemplars.Background
  alias Ecto.Datespan
  import Crit.Exemplars.Background

  # ----------------------------------------------------------------------------
  def bossie_on_disk(_) do 
    span = Datespan.customary(@earliest_date, @latest_date)
    b = 
      background(@bovine_id)
      |> animal("Bossie", available_on: span)
      |> shorthand
    [background: b]
  end

  setup :bossie_on_disk

  def assert_bossie(animal, id) do
    animal
    |> assert_shape(%VM.Animal{})
    |> assert_fields(id: id,
                     lock_version: 1,
                     name: "Bossie",
                     species_name: @bovine,
                     institution: @institution,
                     in_service_datestring: @earliest_iso_date,
                     out_of_service_datestring: @latest_iso_date)
  end

  # ----------------------------------------------------------------------------

  describe "lift" do
    test "a shallow fetch (does not include service gaps)", %{background: b} do
      AnimalApi.one_by_id(b.bossie.id, @institution, preload: [:species])
      |> VM.Animal.lift(@institution)
      |> assert_bossie(b.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "a deeper fetch (does include service gaps)", %{background: b} do
      service_gap_for(b, "Bossie", starting: @date_2, ending: @date_3)
      
      fetched = 
        AnimalApi.one_by_id(b.bossie.id, @institution,
          preload: [:species, :service_gaps])
        |> VM.Animal.lift(@institution)
        |> assert_bossie(b.bossie.id)

      fetched.service_gaps
      |> singleton_payload
      |> assert_shape(%VM.ServiceGap{})
      |> assert_fields(in_service_datestring: @iso_date_2,
                       out_of_service_datestring: @iso_date_3)
    end
  end

  describe "`fetch` from database" do 
    test "fetching a list of animals does not produce service gaps",
      %{background: b} do
      
      VM.Animal.fetch(:all_possible, @institution)
      |> singleton_payload
      |> assert_bossie(b.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for a summary does not produce a service gap",
      %{background: b} do 

      VM.Animal.fetch(:one_for_summary, b.bossie.id, @institution)
      |> assert_bossie(b.bossie.id)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for editing does include service gaps",
      %{background: b} do 

      VM.Animal.fetch(:one_for_edit, b.bossie.id, @institution)
      |> assert_bossie(b.bossie.id)
      |> assert_assoc_loaded(:service_gaps)
    end
  end
end
