defmodule Pile.TimeHelperTest do
  use ExUnit.Case, async: true
  alias Pile.TimeHelper

  test "the current date in a given time zone" do
    # tzdata +/1 times are backward from ISO8601
    earlier = TimeHelper.today_date("Etc/GMT+6")
    later = TimeHelper.today_date("Etc/GMT-8")

    assert Date.diff(later, earlier) == 1
  end
end
  
