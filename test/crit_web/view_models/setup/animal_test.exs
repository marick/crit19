defmodule CritWeb.ViewModels.Setup.AnimalTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: ViewModels
  alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi
  import Crit.Exemplars.Background
  alias Ecto.Datespan
  alias Ecto.Changeset

  setup do
    span = Datespan.customary(@earliest_date, @latest_date)
    b = 
      background(@bovine_id)
      |> animal("Bossie", available_on: span)
      |> shorthand
    [background: b]
  end

  # ----------------------------------------------------------------------------
  def common_to_web_asserts(animal, background) do
    animal
    |> assert_fields(id: background.bossie.id,
                     lock_version: 1,
                     name: "Bossie",
                     species_name: @bovine,
                     institution: @institution,
                     in_service_datestring: @earliest_iso_date,
                     out_of_service_datestring: @latest_iso_date)
  end

  describe "toweb: translation from a shallow fetch" do
    test "a shallow fetch (does not include service gaps)", %{background: b} do
      AnimalApi.one_by_id(b.bossie.id, @institution, preload: [:species])
      |> ViewModels.Animal.to_web(@institution)
      |> common_to_web_asserts(b)
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


  describe "toweb: direct fetch from database" do 
    test "fetching a list of animals does not produce service gaps",
      %{background: b} do
      
      ViewModels.Animal.fetch(:all_possible, @institution)
      |> singleton_payload
      |> common_to_web_asserts(b)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for a summary does not produce a service gap",
      %{background: b} do 

      ViewModels.Animal.fetch(:one_for_summary, b.bossie.id, @institution)
      |> common_to_web_asserts(b)
      |> refute_assoc_loaded(:service_gaps)
    end

    test "fetching an animal for editing does produce a service gap",
      %{background: b} do 

      ViewModels.Animal.fetch(:one_for_edit, b.bossie.id, @institution)
      |> common_to_web_asserts(b)
      |> assert_assoc_loaded(:service_gaps)
    end
  end

  # ----------------------------------------------------------------------------
  describe "changesettery" do

    @no_service_gaps %{
      "id" => "1",
      "lock_version" => "2",
      "name" => "Bossie",
      "species_name" => "species name",
      "institution" => @institution,
      "in_service_datestring" => @earliest_iso_date,
      "out_of_service_datestring" => @latest_iso_date,
      "service_gaps" => []
    }
    
    # In actuality, there will always (as of 2020) be service gaps but
    # let's separate that more complicated handling.
    
    test "success" do
      ViewModels.Animal.form_changeset(@no_service_gaps)
      |> assert_valid
      |> assert_changes(id: 1,
                       lock_version: 2,
                       name: "Bossie",
                       species_name: "species name",
                       institution: @institution,
                       in_service_datestring: @earliest_iso_date,
                       out_of_service_datestring: @latest_iso_date)
    end

    test "required fields are must be present" do
      ViewModels.Animal.form_changeset(%{})
      |> assert_errors(ViewModels.Animal.fields())
    end

    test "dates must be in the right order" do
      params = %{ @no_service_gaps | 
                  "in_service_datestring" => @iso_date_2,
                  "out_of_service_datestring" => @iso_date_2}

      ViewModels.Animal.form_changeset(params)
      |> assert_error(out_of_service_datestring: @date_misorder_message)

      # Fields are available to fill form fields
      |> assert_changes(in_service_datestring: @iso_date_2,
                        out_of_service_datestring: @iso_date_2,
                        name: "Bossie")
    end

    defp with_service_gap(params, service_gap) do
      %{ params | "service_gaps" => [service_gap]}
    end
    
    test "changesets are produced for service gaps: error case" do
      with_service_gap(@no_service_gaps, %{})
      |> ViewModels.Animal.form_changeset
      |> Changeset.get_change(:service_gaps)
      |> singleton_payload
      |> assert_invalid
      |> assert_errors([:in_service_datestring, :out_of_service_datestring, :reason])
    end

    test "a service gap changeset infects the top-level animal service gap" do
      with_service_gap(@no_service_gaps, %{})
      |> ViewModels.Animal.form_changeset
      |> assert_invalid
    end

    @service_gap_params %{
      id: 3,
      reason: "reason",
      institution: @institution,
      in_service_datestring: @iso_date_2,
      out_of_service_datestring: @iso_date_3
    }

    test "the service gap is corrrect" do
      with_service_gap(@no_service_gaps, @service_gap_params)
      |> ViewModels.Animal.form_changeset
      |> assert_valid
    end
  end

  # ----------------------------------------------------------------------------
  
  describe "from_web" do
    @tag :skip
    test "valid are converted" do
      expected = %Schemas.Animal{
        id: 1,
        lock_version: 2,
        name: "Bossie",
        span: Datespan.customary(@earliest_date, @latest_date),
        service_gaps: [
          %Schemas.ServiceGap{
            id: 3,
            reason: "reason",
            span: Datespan.customary(@date_2, @date_3)
          }]
      }

      actual = 
        with_service_gap(@no_service_gaps, @service_gap_params)
        |> ViewModels.Animal.form_changeset
        |> ViewModels.Animal.from_web
        |> assert_shape(%Schemas.Animal{})

      assert actual == expected
    end
  end
end
