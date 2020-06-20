defmodule CritWeb.ViewModels.Setup.AnimalTest do
  use Crit.DataCase, async: true
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi2, as: AnimalApi
  import Crit.Exemplars.Background
  alias Ecto.Datespan
  alias Ecto.Changeset
  import Crit.Exemplars.Background
  
  setup do
    span = Datespan.customary(@earliest_date, @latest_date)
    b = 
      background(@bovine_id)
      |> animal("Bossie", available_on: span)
      |> shorthand
    [background: b]
  end

  # This mimics the actual HTTP params, where a false "reason" will be missing.
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
  @insert_sg_params @base_sg_params
    
  # ----------------------------------------------------------------------------

  test "`update` workflow", %{background: b}  do
    b
    |> service_gap_for("Bossie",
                       name: "update", starting: @earliest_date, ending: @latest_date)
    |> service_gap_for("Bossie",
                       name: "delete")

    animal_view = VM.Animal.fetch(:one_for_edit, b.bossie.id, @institution)
    [update_gap, delete_gap] = animal_view.service_gaps
    
    params_as_displayed =
      %{"name" => animal_view.name,
        "service_gaps" =>
          %{"0" => %{"id" => "",
                     "reason" => "",
                     "in_service_datestring" => "",
                     "out_of_service_datestring" => ""},
            "1" => %{"id" => to_string(update_gap.id),
                     "reason" => update_gap.reason,
                     "in_service_datestring" => update_gap.in_service_datestring,
                     "out_of_service_datestring" => update_gap.out_of_service_datestring},
            "2" => %{"id" => to_string(delete_gap.id),
                     "reason" => delete_gap.reason,
                     "in_service_datestring" => delete_gap.in_service_datestring,
                     "out_of_service_datestring" => delete_gap.out_of_service_datestring}},
        "lock_version" => to_string(animal_view.lock_version),
        "in_service_datestring" => @earliest_iso_date,
        "out_of_service_datestring" => @latest_iso_date
       }

    edited_params =
      params_as_displayed
      |> Map.put("name", "New Bossie")
      |> put_in(["service_gaps", "0"], @insert_sg_params)
      |> put_in(["service_gaps", "1", "out_of_service_datestring"], @never)
      |> put_in(["service_gaps", "2", "delete"], "true")

    vm_changeset = 
      edited_params
      |> VM.Animal.accept_form(@institution)
      |> ok_payload
      |> assert_valid

    repo_changeset =
      VM.Animal.prepare_for_update(b.bossie.id, vm_changeset, @institution)
      |> assert_shape(%Changeset{})
      |> assert_valid

    repo_changeset
    |> VM.Animal.update(@institution)
    |> ok_payload
    |> assert_shape(%VM.Animal{})
    |> assert_field(name: "New Bossie")
    |> refute_assoc_loaded(:service_gaps)
    
    # Let's check what's on disk.
    stored = 
      b.bossie.id
      |> AnimalApi.one_by_id(@institution, preload: [:service_gaps])
      |> assert_shape(%Schemas.Animal{})
      |> assert_field(name: "New Bossie")

    [updated, inserted] = stored.service_gaps |> EnumX.sort_by_id

    inserted
    |> assert_fields(reason: @insert_sg_params["reason"],
                     span: Datespan.customary(@date_2, @date_3))
    updated
    |> assert_fields(reason: update_gap.reason,
                     span: Datespan.inclusive_up(@earliest_date))
  end

  # ----------------------------------------------------------------------------
  describe "changesettery" do

    @no_service_gaps %{
      "id" => "1",
      "lock_version" => "2",
      "name" => "Bossie",
      "species_name" => "species name",
      "in_service_datestring" => @earliest_iso_date,
      "out_of_service_datestring" => @latest_iso_date,
      "service_gaps" => %{}
    }
    
    # In actuality, there will always (as of 2020) be service gaps but
    # let's separate that more complicated handling.
    
    test "success" do
      VM.Animal.accept_form(@no_service_gaps, @institution) |> ok_payload
      |> assert_valid
      |> assert_changes(id: 1,
                       lock_version: 2,
                       name: "Bossie",
                       species_name: "species name",
                       in_service_datestring: @earliest_iso_date,
                       out_of_service_datestring: @latest_iso_date)
    end

    test "required fields are must be present" do
      %{"service_gaps" => %{}}
      |> VM.Animal.accept_form(@institution) |> error2_payload(:form)
      |> assert_invalid
      |> assert_errors(VM.Animal.required())
    end

    test "dates must be in the right order" do
      params = %{ @no_service_gaps | 
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

    defp with_service_gap(top_params, service_gap),
      do: with_service_gaps(top_params, [service_gap])
    
    test "the service gap is correct" do
      with_service_gap(@no_service_gaps, @update_sg_params)
      |> VM.Animal.accept_form(@institution) |> ok_payload
      |> assert_valid      
    end

    test "changesets are produced for service gaps: error case" do
      with_service_gap(@no_service_gaps, @bad_sg_params)
      |> VM.Animal.accept_form(@institution) |> error2_payload(:form)
      |> Changeset.get_change(:service_gaps) |> singleton_payload
      |> assert_invalid
      |> assert_error(:reason)
    end

    test "a service gap changeset infects the animal changeset's validity" do
      # An invalid and valid changeset checks whether ANY of them need to be
      # invalid or ALL of them.
      @no_service_gaps
      |> with_service_gaps([@bad_sg_params, @update_sg_params])
      |> VM.Animal.accept_form(@institution) |> error2_payload(:form)
      |> assert_invalid
    end

    test "empty service gaps are removed" do
      # An invalid and valid changeset checks whether ANY of them need to be
      # invalid or ALL of them.

      [only] = 
        @no_service_gaps
        |> with_service_gaps([@empty_sg_params, @update_sg_params])
        |> VM.Animal.accept_form(@institution) |> ok_payload
        |> Changeset.fetch_change!(:service_gaps)

      assert_change(only, reason: @update_sg_params["reason"])
    end
  end

  # ----------------------------------------------------------------------------


  defp with_service_gaps(top_params, gaps) do
    param_map = 
      gaps
      |> Enum.with_index
      |> Enum.map(fn {gap_params, index} -> {to_string(index), gap_params} end)
      |> Map.new
    %{ top_params | "service_gaps" => param_map}
  end

  
end