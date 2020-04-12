defmodule Crit.Setup.InstitutionApiTest do
  use Crit.DataCase
#  alias Crit.Setup.Schemas.Institution
  alias Crit.Setup.InstitutionApi
  alias Ecto.Timespan
  alias Crit.Exemplars.ReservationFocused

  test "during testing, there's a single institution" do
    [retrieved] = InstitutionApi.all

    assert retrieved.short_name == @institution
    assert [_ | _] = retrieved.timeslots
  end

  test "A single institution can be retrieved" do
    retrieved = InstitutionApi.one!(short_name: @institution)
    assert retrieved.short_name == @institution
    assert [_ | _] = retrieved.timeslots
  end

  test "an institution has a timezone" do
    actual = InstitutionApi.timezone(@institution) 
    assert actual == @default_timezone
  end

  test "an institution has species" do
    actual = InstitutionApi.available_species(@institution)
    expected = [{@bovine, @bovine_id}, {@equine, @equine_id}]
    assert expected == EnumX.id_pairs(actual, :name)
  end

  test "an institution can convert an id to a name" do
    assert InstitutionApi.species_name(@bovine_id, @institution) == @bovine
  end

  test "an institution can convert an id to a timeslot name" do
    some_timeslot = ReservationFocused.timeslot
    actual = InstitutionApi.timeslot_name(some_timeslot.id, @institution)
    assert actual == some_timeslot.name
  end

  test "an institution has time slots" do
    actual = 
      InstitutionApi.timeslot_tuples(@institution)
      |> Enum.map(fn {name, _id} -> name end)

    expected = ["morning (8-noon)",
                "afternoon (1-5)",
                "evening (6-midnight)",
                "all day (8-5)"]
    assert actual == expected
  end

  test "an institution can convert symbolic values to a Timespan" do
    actual = InstitutionApi.timespan(~D[2019-01-01], 1, @institution)
    expected = Timespan.from_date_time_and_duration(~D[2019-01-01], ~T[08:00:00], 4 * 60)
    assert actual == expected
  end
  
end
