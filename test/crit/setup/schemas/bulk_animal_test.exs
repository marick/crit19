defmodule Crit.Setup.Animal.Schemas.BulkAnimalTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.BulkAnimal
  alias Ecto.Datespan

  @correct %{
    names: "a, b, c",
    species_id: "1",
    in_service_datestring: @iso_date,
    out_of_service_datestring: @later_iso_date,
    institution: @institution
  }

  describe "changeset" do
    test "required fields are checked" do
      errors =
        %{} |> BulkAnimal.creation_changeset |> errors_on
      
      assert errors.names
      assert errors.species_id
      assert errors.in_service_datestring
      assert errors.out_of_service_datestring
    end

    test "the construction of cast and derived values" do
      BulkAnimal.creation_changeset(@correct)
      |> assert_valid
      |> assert_changes(species_id: 1,
                        computed_names: ["a", "b", "c"],
                        span: Datespan.customary(@date, @later_date))
    end
  end
end
  
