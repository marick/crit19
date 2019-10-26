defmodule Crit.Usables.Animal.Schemas.BulkAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.BulkAnimal
  alias Crit.Usables.Schemas.Animal
  # alias Ecto.Datespan

  @correct %{
    names: "a, b, c",
    species_id: "1",
    in_service_datestring: @iso_date,
    out_of_service_datestring: @later_iso_date,
    timezone: "America/Chicago",
  }

  describe "changeset" do
    test "required fields are checked" do
      errors = %{} |> BulkAnimal.compute_insertables |> errors_on
      
      assert errors.names
      assert errors.species_id
      assert errors.in_service_datestring
      assert errors.out_of_service_datestring
    end

    test "the construction of cast and derived values" do
      changeset = BulkAnimal.compute_insertables(@correct)
      assert changeset.valid?

      changes = changeset.changes
      assert changes.species_id == 1
      assert changes.computed_names == ["a", "b", "c"]
      assert changes.in_service_date == @date
      assert changes.out_of_service_date == @later_date
    end
  end

  describe "breaking a valid changeset into changesets for insertion" do
    defp make_changeset(in_service_string, out_of_service_string) do
      base = %{
        names: "one, two",
        species_id: "1",
        timezone: "America/Chicago",
      }
      base
      |> Map.put(:in_service_datestring,  in_service_string)
      |> Map.put(:out_of_service_datestring, out_of_service_string)
      |> BulkAnimal.compute_insertables
      |> BulkAnimal.changeset_to_changesets
    end
    
    test "has no out-of-service date" do 
      [one_cs, two_cs] = make_changeset(@iso_date, @never)
      
      assert one_cs.changes.name == "one"
      assert one_cs.changes.species_id == 1
      assert one_cs.changes.in_service_date == @date
      refute one_cs.changes[:out_of_service_date]
      assert one_cs.data == %Animal{}
      
      assert two_cs.changes.name == "two"
      # Rest is the same
      assert two_cs.changes.species_id == 1
      assert two_cs.changes.in_service_date == @date
      refute two_cs.changes[:out_of_service_date]
      assert two_cs.data == %Animal{}
    end

    test "has an out-of-service date" do 
      [one_cs, _two_cs] = make_changeset(@iso_date, @later_iso_date)
      
      assert one_cs.changes.in_service_date == @date
      assert one_cs.changes.out_of_service_date == @later_date
    end
    
  end
end
  
