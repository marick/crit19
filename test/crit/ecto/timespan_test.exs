defmodule Crit.Ecto.TimespanTest do

  # Tests for functions specific to Timespan.
  
  use Crit.DataCase
  alias Ecto.Timespan
  alias Pile.TimeHelper

  test "plus" do
    plus_form = Timespan.plus(          ~N[2001-01-01 01:02:03], 10, :minute)
    customary_form = Timespan.customary(~N[2001-01-01 01:02:03],
                                        ~N[2001-01-01 01:12:03])
    assert plus_form == customary_form
  end


  test "conversions" do
    actual =
      Timespan.from_date_time_and_duration(~D[2019-11-12], ~T[08:00:00], 90)
    # We match the microsecond precision that Postgres gives us.
    expected_start = ~N[2019-11-12 08:00:00] |> TimeHelper.millisecond_precision
    expected_end =   ~N[2019-11-12 09:30:00] |> TimeHelper.millisecond_precision
    assert actual == Timespan.customary(expected_start, expected_end)
  end
end
