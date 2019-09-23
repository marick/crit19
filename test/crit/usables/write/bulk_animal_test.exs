defmodule Crit.Usables.Write.BulkAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Write.BulkAnimal
  alias Pile.TimeHelper

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2200-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

  @correct %{
    names: "a, b, c",
    species_id: 1,
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

      assert errors.names == [BulkAnimal.no_names_error_message]
    end
  end

  describe "changeset: handling the dates" do
    test "explicit dates" do
      changeset = 
        @correct
        |> Map.put(:start_date, @iso_date)
        |> Map.put(:end_date, @later_iso_date)
        |> BulkAnimal.compute_insertables

      assert changeset.valid?
      assert changeset.changes.computed_start_date == @date
      assert changeset.changes.computed_end_date == @later_date
    end

    test "starting date is today" do
      changeset = 
        @correct
        |> Map.put(:start_date, "today")
        |> Map.put(:end_date, @later_iso_date)
        |> BulkAnimal.compute_insertables

      today = TimeHelper.today_date(changeset.changes.timezone)
      
      # Yes, this test will fail if it runs across a date boundary. So sue me.
      assert changeset.valid?
      assert changeset.changes.computed_start_date == today
      assert changeset.changes.computed_end_date == @later_date
    end

    test "ending day is 'never', which does not set computed value" do
      changeset = 
        @correct
        |> Map.put(:start_date, @iso_date)
        |> Map.put(:end_date, "never")
        |> BulkAnimal.compute_insertables

      assert changeset.valid?
      assert changeset.changes.computed_start_date == @date
      assert changeset.changes.computed_end_date == :missing
    end

    test "are in the wrong order" do
      errors = 
        @correct
        |> Map.put(:start_date, @later_iso_date)
        |> Map.put(:end_date, @iso_date)
        |> BulkAnimal.compute_insertables
        |> errors_on

      assert errors.end_date == [BulkAnimal.misorder_error_message]
    end
    

    test "for completeness, a supposedly impossible ill-formed date" do
      errors = 
        @correct
        |> Map.put(:start_date, "todya")
        |> Map.put(:end_date, "ne")
        |> BulkAnimal.compute_insertables
        |> errors_on

      assert errors.start_date == [BulkAnimal.parse_error_message]
      assert errors.end_date == [BulkAnimal.parse_error_message]
    end
  end

  describe "changeset: handling the service gaps" do
    test "two gaps" do
      changeset = 
        @correct
        |> Map.put(:start_date, @iso_date)
        |> Map.put(:end_date, @later_iso_date)
        |> BulkAnimal.compute_insertables

      assert changeset.valid?
      assert [in_service, out_of_service] = changeset.changes.computed_service_gaps

      assert_strictly_before(in_service.gap, @date)
      assert in_service.reason == "before animal was put in service"

      assert_date_and_after(out_of_service.gap, @later_date)
      assert out_of_service.reason == "animal taken out of service"
    end

    test "one gap" do
      changeset = 
        @correct
        |> Map.put(:start_date, @iso_date)
        |> Map.put(:end_date, "never")
        |> BulkAnimal.compute_insertables

      assert changeset.valid?
      assert [in_service] = changeset.changes.computed_service_gaps

      assert_strictly_before(in_service.gap, @date)
      assert in_service.reason == "before animal was put in service"
    end
  end
end
  
