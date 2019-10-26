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
      errors = %{} |> BulkAnimal.creation_changeset |> errors_on
      
      assert errors.names
      assert errors.species_id
      assert errors.in_service_datestring
      assert errors.out_of_service_datestring
    end

    test "the construction of cast and derived values" do
      changeset = BulkAnimal.creation_changeset(@correct)
      assert changeset.valid?

      changes = changeset.changes
      assert changes.species_id == 1
      assert changes.computed_names == ["a", "b", "c"]
      assert changes.in_service_date == @date
      assert changes.out_of_service_date == @later_date
    end
  end
end
  
