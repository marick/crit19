defmodule Crit.ServiceGapTest do
  use Crit.DataCase, async: true
  alias Crit.Usables.{ServiceGap}
  alias Ecto.Datespan
  alias Pile.TimeHelper

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  # Note: technically, comparing Dates (and thus Datespans) using `==` is
  # a no-no. However, read the following as a mock-style expectation. Or
  # just that I'm too lazy to implement comparisons just for tests.

  describe "pre_service_changeset" do
    test "starts on a given date" do
      changeset = ServiceGap.pre_service_changeset(
        %{"start_date" => @iso_date})
      assert changeset.valid?
      assert changeset.changes.gap == Datespan.infinite_down(@date, :exclusive)
      assert changeset.changes.reason == "before animal was put in service"
    end

    test "starts today (in institution's time zone)" do
      institution_timezone = "America/Chicago"
      
      changeset = ServiceGap.pre_service_changeset(
        %{"start_date" => "today",
          "timezone" => institution_timezone
        },
        TimeHelper.stub_today_date(institution_timezone, to_return: @date))

      assert changeset.valid?
      assert changeset.changes.gap == Datespan.infinite_down(@date, :exclusive)
    end

    test "bad format (should be impossible, but..." do
      changeset = ServiceGap.pre_service_changeset(
        %{"start_date" => "i am not a date"})
      refute changeset.valid?
      assert ServiceGap.parse_message in errors_on(changeset).start_date
    end
  end
end
