defmodule Crit.Usables.Animal.Schemas.BulkAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.BulkAnimal
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

  @tag :skip
  test "breaking a valid changeset into changesets for insertion" do
    [_one_cs, _two_cs] = 
      @correct
      |> Map.put(:names,  "one, two")
      |> Map.put(:species, "1")
      |> Map.put(:in_service_date,  @iso_date)
      |> Map.put(:out_of_service_date, @never)
      |> BulkAnimal.compute_insertables
      |> BulkAnimal.changeset_to_changesets

    # assert one_cs.changes.name == "one"
    # assert one_cs.changes.species_id == 1
    # assert [gap_cs] = one_cs.changes.service_gaps
    # assert gap_cs.changes.gap == Datespan.strictly_before(@date)

    # assert two_cs.changes.name == "two"
    # # Rest is the same
    # assert two_cs.changes.species_id == 1
    # assert [gap_cs] = two_cs.changes.service_gaps
    # assert gap_cs.changes.gap == Datespan.strictly_before(@date)
  end
  
end
  
