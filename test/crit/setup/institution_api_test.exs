defmodule Crit.Setup.InstitutionApiTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.Institution
  alias Crit.Setup.InstitutionApi
  alias Ecto.Timespan

  test "the institutions are preloaded when app starts" do
    assert InstitutionApi.all == Repo.all(Institution) |> Repo.preload(:time_slots)
  end

  test "during testing, there's a single institution" do
    assert [_] = InstitutionApi.all
  end
  
  test "the institution is labeled with a special shortname" do
    [retrieved] = InstitutionApi.all

    assert retrieved.short_name == @institution
  end

  test "A single institution can be retrieved" do
    retrieved = InstitutionApi.one!(short_name: @institution)
    assert retrieved.short_name == @institution
  end

  test "an institution has a timezone" do
    actual = InstitutionApi.timezone(@institution) 
    assert actual == InstitutionApi.default.timezone
  end

  test "an institution has tuples of species" do
    actual = InstitutionApi.available_species(@institution)
    expected = [{@bovine, @bovine_id}, {@equine, @equine_id}]
    assert actual == expected
  end

  test "an institution can convert an id to a species" do
    assert InstitutionApi.species_name(@bovine_id, @institution) == @bovine
  end

  test "an institution can convert an id to a timeslot name" do
    actual = InstitutionApi.time_slot_name(1, @institution)
    assert actual == @institution_first_time_slot.name
  end

  test "an institution has time slots" do
    actual = 
      InstitutionApi.time_slot_tuples(@institution)
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
