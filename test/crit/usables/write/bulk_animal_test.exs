defmodule Crit.Usables.Write.BulkAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Write.BulkAnimal

  @correct %{
    names: "a, b, c",
    species_id: 1,
    start_date: "2012-05-06",
    end_date: "2013-06-09",
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

    @tag :skip
    test "computations" do
    end
  end

  describe "changeset: handling the name field" do
    test "computes names and handles whitespace" do
      changeset = 
        @correct
        |> Map.put(:names, "  a, bb  , c   d ")
        |> BulkAnimal.compute_insertables
      
      assert changeset.changes.computed_names == ["a", "bb", "c   d"]
    end

    test "will reject sneaky way of getting an empty list" do
      errors = 
        @correct
        |> Map.put(:names, " ,")
        |> BulkAnimal.compute_insertables
        |> errors_on

      assert errors.names
    end
  end

  describe "changeset: handling the dates" do
    test "explicit dates" do
      changeset = 
        @correct
        |> Map.put(:start_date, "2012-05-06")
        |> Map.put(:end_date, "2013-06-09"

      assert changeset.valid?
      assert changeset.changes.computed_start_date == ~D[2012-05-06]
      assert changeset.changes.computed_end_date == ~D[2013-06-09]
    end
  end
end
