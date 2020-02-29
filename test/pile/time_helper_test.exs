defmodule Pile.TimeHelperTest do
  use ExUnit.Case, async: true
  alias Pile.TimeHelper

  test "the current date in a given time zone" do
    # tzdata +/1 times are backward from ISO8601
    earlier = TimeHelper.today_date("Etc/GMT+6")
    later = TimeHelper.today_date("Etc/GMT-6")

    {{_y, _mo, _d}, {hour, _m, _s}} = NaiveDateTime.utc_now |> NaiveDateTime.to_erl
    
    expected = if hour >= 18 || hour < 6, do: 1, else: 0
    assert Date.diff(later, earlier) == expected
  end

  describe "millisecond precision" do
    test "for Dates" do
      actual = TimeHelper.millisecond_precision(~D[2019-09-23])
      expected = NaiveDateTime.from_erl!({{2019, 9, 23}, {0, 0, 0}}, {0, 6})
      assert actual == expected
    end

    test "for NaiveDateTimes" do
      actual = TimeHelper.millisecond_precision(~N[2019-09-23 01:02:03])
      expected = NaiveDateTime.from_erl!({{2019, 9, 23}, {1, 2, 3}}, {0, 6})
      assert actual == expected
    end
    
  end

  test "week_dates" do
    sunday = ~D[2020-03-29]
    tuesday = ~D[2020-03-31]
    saturday = ~D[2020-04-04]

    assert {sunday, saturday} == TimeHelper.week_dates(sunday)
    assert {sunday, saturday} == TimeHelper.week_dates(tuesday)
    assert {sunday, saturday} == TimeHelper.week_dates(saturday)
  end
end
  
