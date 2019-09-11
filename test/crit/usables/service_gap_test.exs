defmodule Crit.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.{ServiceGap}
  alias Ecto.Datespan

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  # Note: technically, comparing Dates (and thus Datespans) using `==` is
  # a no-no. However, read the following as a mock-style expectation. Or
  # just that I'm too lazy to implement comparisons just for tests.
  
  describe "pre_service_changeset" do
    test "starts on a given date" do
      changeset = ServiceGap.pre_service_changeset(%ServiceGap{},
        %{"start_date" => @iso_date})
      assert changeset.valid?
      assert changeset.changes.gap == Datespan.infinite_down(@date, :exclusive)
      assert changeset.changes.reason == "before animal was put in service"
    end

    @tag :skip
    test "starts today (in institution's time zone)" do
      changeset = ServiceGap.pre_service_changeset(%ServiceGap{},
        %{"start_date" => "today"})
      assert changeset.valid?
      assert changeset.changes.gap == Datespan.infinite_up(@date, :inclusive)
    end

    test "bad format (should be impossible, but..." do
      changeset = ServiceGap.pre_service_changeset(%ServiceGap{},
        %{"start_date" => "bon"})
      refute changeset.valid?
      assert ServiceGap.parse_message in errors_on(changeset).start_date
    end
  end
end
