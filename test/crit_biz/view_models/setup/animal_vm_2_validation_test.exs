defmodule CritBiz.ViewModels.Setup.AnimalVM.ValidationTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Ecto.Datespan
  alias Ecto.Changeset
  alias Crit.Exemplars.Params
  use FlowAssertions.Ecto
  import Crit.Assertions.Form

  @base_animal %{
      "id" => "1",
      "lock_version" => "2",
      "name" => "Bossie",
      "species_name" => "species name",
      "in_service_datestring" => @earliest_iso_date,
      "out_of_service_datestring" => @latest_iso_date,
      "service_gaps" => %{}
  }

  # Note: here we assume that `delete` wasn't checked, in which case
  # it will have no value.
  
  @empty_sg_params %{
    "reason" => "",
    "in_service_datestring" => "",
    "out_of_service_datestring" => "",
  }

  @base_sg_params %{
    "reason" => "reason",
    "in_service_datestring" => @iso_date_2,
    "out_of_service_datestring" => @iso_date_3,
  }
  
  @bad_sg_params %{@base_sg_params | "reason" => "" }
  @update_sg_params @base_sg_params |> Map.put("id", "4")
    
  # ----------------------------------------------------------------------------
  describe "successful form validation" do
    
    # In actuality, there will always (as of 2020) be service gaps but
    # let's separate that more complicated handling.
    
    test "success" do
      VM.Animal.accept_form(@base_animal, @institution) |> ok_content
      |> assert_valid
      |> assert_changes(id: 1,
                       lock_version: 2,
                       name: "Bossie",
                       species_name: "species name",
                       in_service_datestring: @earliest_iso_date,
                       out_of_service_datestring: @latest_iso_date)
    end

    test "empty insertion params are not subject to validation" do
      [empty, only] = 
        @base_animal
        |> Params.put_nested("service_gaps", [@empty_sg_params, @update_sg_params])
        |> VM.Animal.accept_form(@institution) |> ok_content
        |> Changeset.fetch_change!(:service_gaps)

      empty
      |> assert_no_changes
      |> refute_form_will_display_errors

      only
      |> assert_change(reason: @update_sg_params["reason"])
      |> refute_form_will_display_errors
    end

    test "helper function `lower_to_attrs`" do  
      expected = %{
        # Id is not included for animal update
        lock_version: 2,
        name: "Bossie",
        span: Datespan.customary(@earliest_date, @latest_date),
        service_gaps: [
          %{id: @update_sg_params["id"] |> String.to_integer,
            reason: @update_sg_params["reason"],
            span: Datespan.customary(@date_2, @date_3)
          }]
      }

      actual =
        @base_animal
        |> Params.put_nested("service_gaps", [@update_sg_params])
        |> VM.Animal.accept_form(@institution)
        |> ok_content
        |> VM.Animal.lower_to_attrs

      assert actual == expected
    end
  end

  describe "validation failures" do 
    test "required fields are must be present" do
      %{"service_gaps" => %{}}
      |> VM.Animal.accept_form(@institution) |> error2_content(:form)
      |> assert_invalid
      |> assert_errors(VM.Animal.required())
      |> assert_form_will_display_errors
    end

    test "dates must be in the right order" do
      params = %{ @base_animal | 
                  "in_service_datestring" => @iso_date_2,
                  "out_of_service_datestring" => @iso_date_2}

      VM.Animal.accept_form(params, @institution) |> error2_content(:form)
      |> assert_invalid
      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_form_will_display_errors

      # Fields are available to fill form fields
      |> assert_changes(in_service_datestring: @iso_date_2,
                        out_of_service_datestring: @iso_date_2,
                        name: "Bossie")
    end

    test "the service gap is correct" do
      @base_animal
      |> Params.put_nested("service_gaps", [@update_sg_params])
      |> VM.Animal.accept_form(@institution) |> ok_content
      |> assert_valid      
      |> refute_form_will_display_errors
    end

    test "changesets are produced for service gaps: error case" do
      @base_animal
      |> Params.put_nested("service_gaps", [@bad_sg_params])
      |> VM.Animal.accept_form(@institution) |> error2_content(:form)
      |> Changeset.get_change(:service_gaps) |> singleton_content
      |> assert_invalid
      |> assert_error(:reason)
      |> assert_form_will_display_errors
    end

    test "a service gap changeset infects the animal changeset's validity" do
      # An invalid and valid changeset checks whether ANY of them need to be
      # invalid or ALL of them.
      @base_animal
      |> Params.put_nested("service_gaps", [@bad_sg_params, @update_sg_params])
      |> VM.Animal.accept_form(@institution) |> error2_content(:form)
      |> assert_invalid
      |> assert_form_will_display_errors
    end
  end
end
