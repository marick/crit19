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

  @base_sg_params %{
    "reason" => "reason",
    "in_service_datestring" => @iso_date_2,
    "out_of_service_datestring" => @iso_date_3,
  }
  
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
end
