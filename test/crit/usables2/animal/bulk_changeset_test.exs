defmodule Crit.Usables.Animal.BulkChangesetTest do
  use Crit.DataCase
  alias Crit.Usables.Animal.BulkCreation

  @correct %{
    names: "a, b, c",
    species_id: "1",
    start_date: @iso_date,
    end_date: @later_iso_date,
    timezone: "America/Chicago",
  }

  describe "changeset" do
    test "required fields are checked" do
      errors = %{} |> BulkCreation.compute_insertables |> errors_on
      
      assert errors.names
      assert errors.species_id
      assert errors.start_date
      assert errors.end_date
    end

    test "the construction derived/virtual values" do
      changeset = BulkCreation.compute_insertables(@correct)
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

  test "breaking a valid changeset into changesets for insertion" do
    %{animal_changesets: [one_cs, two_cs],
      service_gap_changesets: [gap_cs]
    } =
      @correct
      |> Map.put(:names,  "one, two")
      |> Map.put(:species, "1")
      |> Map.put(:start_date,  @iso_date)
      |> Map.put(:end_date, @never)
      |> BulkCreation.compute_insertables
      |> BulkCreation.changeset_to_changesets

    assert one_cs.changes.name == "one"
    assert one_cs.changes.species_id == 1
    assert two_cs.changes.name == "two"
    
    assert_strictly_before(gap_cs.changes.gap, @date)
    assert gap_cs.changes.reason == "before animal was put in service"
  end
end
  
