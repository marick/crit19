defmodule CritWeb.ViewModels.Setup.AnimalVM.ValidationTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  alias Ecto.Datespan
  alias Ecto.Changeset

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
  @update_sg_params @base_sg_params |> Map.put("id", 4)
    
  # ----------------------------------------------------------------------------
  describe "successful form validation" do
    
    # In actuality, there will always (as of 2020) be service gaps but
    # let's separate that more complicated handling.
    
    test "success" do
      VM.Animal.accept_form(@base_animal, @institution) |> ok_payload
      |> assert_valid
      |> assert_changes(id: 1,
                       lock_version: 2,
                       name: "Bossie",
                       species_name: "species name",
                       in_service_datestring: @earliest_iso_date,
                       out_of_service_datestring: @latest_iso_date)
    end

    test "empty service gaps are removed, not subject to validation" do
      # An invalid and valid changeset checks whether ANY of them need to be
      # invalid or ALL of them.

      [only] = 
        @base_animal
        |> with_service_gaps([@empty_sg_params, @update_sg_params])
        |> VM.Animal.accept_form(@institution) |> ok_payload
        |> Changeset.fetch_change!(:service_gaps)

      assert_change(only, reason: @update_sg_params["reason"])
    end

    test "helper function `update_params`" do  
      expected = %{
        # Id is not included for animal update
        lock_version: 2,
        name: "Bossie",
        span: Datespan.customary(@earliest_date, @latest_date),
        service_gaps: [
          %{id: @update_sg_params["id"],
            reason: @update_sg_params["reason"],
            span: Datespan.customary(@date_2, @date_3)
          }]
      }

      actual = 
        with_service_gap(@base_animal, @update_sg_params)
        |> VM.Animal.accept_form(@institution)
        |> ok_payload
        |> VM.Animal.update_params

      assert actual == expected
    end
  end

  describe "validation failures" do 
    test "required fields are must be present" do
      %{"service_gaps" => %{}}
      |> VM.Animal.accept_form(@institution) |> error2_payload(:form)
      |> assert_invalid
      |> assert_errors(VM.Animal.required())
    end

    test "dates must be in the right order" do
      params = %{ @base_animal | 
                  "in_service_datestring" => @iso_date_2,
                  "out_of_service_datestring" => @iso_date_2}

      VM.Animal.accept_form(params, @institution) |> error2_payload(:form)
      |> assert_invalid
      |> assert_error(out_of_service_datestring: @date_misorder_message)

      # Fields are available to fill form fields
      |> assert_changes(in_service_datestring: @iso_date_2,
                        out_of_service_datestring: @iso_date_2,
                        name: "Bossie")
    end

    test "the service gap is correct" do
      with_service_gap(@base_animal, @update_sg_params)
      |> VM.Animal.accept_form(@institution) |> ok_payload
      |> assert_valid      
    end

    test "changesets are produced for service gaps: error case" do
      with_service_gap(@base_animal, @bad_sg_params)
      |> VM.Animal.accept_form(@institution) |> error2_payload(:form)
      |> Changeset.get_change(:service_gaps) |> singleton_payload
      |> assert_invalid
      |> assert_error(:reason)
    end

    test "a service gap changeset infects the animal changeset's validity" do
      # An invalid and valid changeset checks whether ANY of them need to be
      # invalid or ALL of them.
      @base_animal
      |> with_service_gaps([@bad_sg_params, @update_sg_params])
      |> VM.Animal.accept_form(@institution) |> error2_payload(:form)
      |> assert_invalid
    end
  end

  # ----------------------------------------------------------------------------
  defp with_service_gaps(top_params, gaps) when is_list(gaps) do
    param_map = 
      gaps
      |> Enum.with_index
      |> Enum.map(fn {gap_params, index} -> {to_string(index), gap_params} end)
      |> Map.new
    %{ top_params | "service_gaps" => param_map}
  end

  defp with_service_gap(top_params, service_gap),
    do: with_service_gaps(top_params, [service_gap])
end
