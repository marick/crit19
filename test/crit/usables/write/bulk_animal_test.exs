defmodule Crit.Usables.Write.BulkAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Write.BulkAnimal

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2200-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

  @correct %{
    names: "a, b, c",
    species_id: "1",
    start_date: @iso_date,
    end_date: @later_iso_date,
    timezone: "America/Chicago",
  }

  describe "changeset" do
    test "required fields" do
      errors = %{} |> BulkAnimal.compute_insertables |> errors_on
      
      assert errors.names
      assert errors.species_id
      assert errors.start_date
      assert errors.end_date
    end

    test "computations" do
      changeset = BulkAnimal.compute_insertables(@correct)
      assert changeset.valid?

      changes = changeset.changes
      assert changes.computed_names == ["a", "b", "c"]
      assert changes.species_id == 1

      assert [in_service, out_of_service] = changes.computed_service_gaps
      assert_strictly_before(in_service.gap, @date)
      assert in_service.reason == "before animal was put in service"

      assert_date_and_after(out_of_service.gap, @later_date)
      assert out_of_service.reason == "animal taken out of service"
    end
  end

end
  
