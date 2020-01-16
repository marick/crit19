defmodule Crit.Usables.AnimalImpl.UpdateUpdateServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.ServiceGap
  alias Crit.Usables.AnimalApi
  alias Crit.Extras.AnimalT
  alias Ecto.Datespan

  describe "successfully updating a service gap" do
    setup do
      %{id: animal_id} =
        Factory.sql_insert!(:animal, [span: Datespan.inclusive_up(@date)], @institution)
          

      Factory.sql_insert!(:service_gap,
        [animal_id: animal_id,
         span: Datespan.customary(@date, @bumped_date)],
        @institution)

      # # A second service gap that is to be unchanged.
      Factory.sql_insert!(:service_gap,
        [animal_id: animal_id,
         span: Datespan.customary(@later_date, @later_bumped_date)],
        @institution)

      [animal: AnimalApi.updatable!(animal_id, @institution)]
    end

    test "successful update with changes to animal and a service gap", 
    %{animal: animal} do

      new_name = "this is a new animal name"
      params =
        AnimalT.unchanged_params(animal)
        |> Map.put("name", new_name)
        |> put_in(["service_gaps", "1", "out_of_service_datestring"],
                  @later_iso_date)

      new_animal = AnimalT.update_for_success(animal.id, params)

      assert_copy(new_animal, animal,
        except: [name: new_name],
        ignoring: [:lock_version, :service_gaps, :updated_at])

      # Note that the returned value is suitable for another form.
      assert_copy(AnimalT.service_gap_n(new_animal, 0),
                  AnimalT.service_gap_n(    animal, 0),
        except: [out_of_service_datestring: @later_iso_date,
                 span: Datespan.customary(@date, @later_date)])

      assert_copy(AnimalT.service_gap_n(new_animal, 1),
                  AnimalT.service_gap_n(    animal, 1))
    end

    test "failing to update both animal and service gap", %{animal: animal} do

      params =
        AnimalT.unchanged_params(animal)
        |> Map.put("in_service_datestring", @later_iso_date)
        |> put_in(["service_gaps", "1", "out_of_service_datestring"], @iso_date)

      error_changeset = AnimalT.update_for_error_changeset(animal.id, params)

      # Check that that the animal will be displayed with the changed value
      assert_change(error_changeset, in_service_datestring: @later_iso_date)

      [empty, changed_sg, unchanged_sg] = error_changeset.changes.service_gaps
      assert_no_changes(empty)
      assert empty.data == %ServiceGap{}
      assert_change(changed_sg, out_of_service_datestring: @iso_date)
      assert_no_changes(unchanged_sg)
    end


    test "what happens when ONLY an animal update fails", %{animal: animal} do
      Factory.sql_insert!(:animal, [name: "conflicting name"], @institution)

      params =
        AnimalT.unchanged_params(animal)
        |> Map.put("name", "conflicting name")
        # This is a valid change
        |> put_in(["service_gaps", "1", "out_of_service_datestring"],
                  @later_iso_date)

      error_changeset = AnimalT.update_for_error_changeset(animal.id, params)

      assert_change(error_changeset, name: "conflicting name")

      [empty, changed_sg, unchanged_sg] = error_changeset.changes.service_gaps
      assert_no_changes(empty)
      assert empty.data == %ServiceGap{}
      assert_change(changed_sg, out_of_service_datestring: @later_iso_date)
      assert_no_changes(unchanged_sg)
    end

    test "what happens when ONLY a changeset update fails", %{animal: animal} do
      params =
        AnimalT.unchanged_params(animal)
        |> Map.put("name", "non-conflicting name")
        |> put_in(["service_gaps", "1", "out_of_service_datestring"],
                  @iso_date)

      error_changeset = AnimalT.update_for_error_changeset(animal.id, params)

      [empty, changed_sg, unchanged_sg] = error_changeset.changes.service_gaps
      assert_no_changes(empty)
      assert empty.data == %ServiceGap{}
      assert_change(changed_sg, out_of_service_datestring: @iso_date)
      assert_no_changes(unchanged_sg)
    end
  end
end
