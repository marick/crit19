defmodule Pile.TimeHelperTest do
  use ExUnit.Case, async: true
  alias Pile.TimeHelper

  describe "date_to_start_of_day" do
    test "exact date" do
      result = TimeHelper.location_day("2019-09-04", "America/Chicago")
      assert result == ~D[2019-09-04]
    end

    test "date in a time zone" do
      # tzdata +/1 times are backward from ISO8601
      earlier = TimeHelper.location_day("today", "Etc/GMT+6")
      later = TimeHelper.location_day("today", "Etc/GMT-6")

      assert Date.diff(later, earlier) == 1
    end
    
  end
  
end
  
