defmodule Crit.Usables.AnimalImpl.UpdateUpdateServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.Animal
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars.Available
  alias Crit.Extras.AnimalT
  alias Crit.Extras.ServiceGapT
  alias Ecto.Changeset
  alias Ecto.Datespan
  alias Crit.Usables.AnimalImpl.Write

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

    test "successful update with changes to animal and a changeset", 
    %{animal: animal} do

      new_name = "this is a new animal name"
      params =
        AnimalT.params(animal)
        |> Map.put("name", new_name)
        |> put_in(["service_gaps", "0", "out_of_service_datestring"],
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
      
      Factory.sql_insert!(:animal, [name: "conflicting name"], @institution)

      params =
        AnimalT.params(animal)
        |> Map.put("in_service_datestring", @later_iso_date)
        |> put_in(["service_gaps", "0", "out_of_service_datestring"], @iso_date)

      error_changeset = AnimalT.update_for_error_changeset(animal.id, params)

      # Check that that the animal will be displayed the same way.
      form_changeset = Animal.form_changeset(animal)
      assert_copy(form_changeset.data, error_changeset.data)
      assert Ecto.assoc_loaded?(error_changeset.data.service_gaps)

      assert_change(error_changeset, in_service_datestring: @later_iso_date)

      # Note that both error changesets appear, even the unchanged one.
      # That's because Ecto upsert requires either nothing or a complete
      # description of the updated association.

      [changed_sg, unchanged_sg] = error_changeset.changes.service_gaps
      assert_change(changed_sg, out_of_service_datestring: @iso_date)
      assert_no_changes(unchanged_sg)
    end


  end
end
