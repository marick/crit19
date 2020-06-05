defmodule CritWeb.ViewModels.Setup.AnimalTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: ViewModels
  # alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi
  import Crit.Exemplars.Background
  alias Ecto.Datespan

  setup do
    span = Datespan.customary(@earliest_date, @latest_date)
    b = 
      background(@bovine_id)
      |> animal("Bossie", available_on: span)
      |> shorthand
    [background: b]
  end

  def common_asserts(animal, background) do
    animal
    |> assert_fields(id: background.bossie.id,
                     lock_version: 1,
                     name: "Bossie",
                     species_name: @bovine,
                     institution: @institution,
                     in_service_datestring: @earliest_iso_date,
                     out_of_service_datestring: @latest_iso_date)
  end

  describe "translation from a shallow fetch" do
    test "a shallow fetch (does not include service gaps)", %{background: b} do
      AnimalApi.one_by_id(b.bossie.id, @institution, preload: [:species])
      |> ViewModels.Animal.to_web(@institution)
      |> common_asserts(b)
      |> refute_assoc_loaded(:service_gaps)
    end


    test "a deeper fetch (does include service gaps)", %{background: b} do
      service_gap_for(b, "Bossie", starting: @date_2, ending: @date_3)
      
      fetched = 
        AnimalApi.one_by_id(b.bossie.id, @institution,
          preload: [:species, :service_gaps])
        |> ViewModels.Animal.to_web(@institution)


      fetched.service_gaps
      |> singleton_payload
      |> assert_shape(%ViewModels.ServiceGap{})
      |> assert_fields(in_service_datestring: @iso_date_2,
                       out_of_service_datestring: @iso_date_3)
    end
  end


  describe "direct fetch from database" do 
    test "fetching a list of animals does not produce service gaps",
      %{background: b} do
      
      ViewModels.Animal.fetch(:all_possible, @institution)
      |> singleton_payload
      |> common_asserts(b)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for a summary does not produce a service gap",
      %{background: b} do 

      ViewModels.Animal.fetch(:one_for_summary, b.bossie.id, @institution)
      |> common_asserts(b)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for editing does produce a service gap",
      %{background: b} do 

      ViewModels.Animal.fetch(:one_for_edit, b.bossie.id, @institution)
      |> common_asserts(b)
      |> assert_assoc_loaded(:service_gaps)
    end
  end
end
