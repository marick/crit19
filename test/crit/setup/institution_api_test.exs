defmodule Crit.Servers.InstitutionTest do
  use Crit.DataCase
#  alias Crit.Schemas.Institution
  alias Crit.Servers.Institution
  alias Ecto.Timespan
  alias Crit.Exemplars.ReservationFocused

  test "an institution has a timezone" do
    actual = Institution.timezone(@institution) 
    assert actual == @default_timezone
  end

  test "an institution has species" do
    actual = Institution.species(@institution)
    expected = [{@bovine, @bovine_id}, {@equine, @equine_id}]
    assert expected == EnumX.id_pairs(actual, :name)
  end

  test "an institution can convert an id to a name" do
    assert Institution.species_name(@bovine_id, @institution) == @bovine
  end

  test "an institution can convert an id to a timeslot name" do
    some_timeslot = ReservationFocused.timeslot
    actual = Institution.timeslot_name(some_timeslot.id, @institution)
    assert actual == some_timeslot.name
  end

  test "an institution can convert symbolic values to a Timespan" do
    actual = Institution.timespan(~D[2019-01-01], 1, @institution)
    expected = Timespan.from_date_time_and_duration(~D[2019-01-01], ~T[08:00:00], 4 * 60)
    assert actual == expected
  end
  
end
