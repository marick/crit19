defmodule Crit.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.{ServiceGap}
  alias Ecto.Datespan

  @iso_date "2001-09-05"
  @iso_later_date "2019-09-05"

  @date Date.from_iso8601!(@iso_date)
  @later_date Date.from_iso8601!(@iso_later_date)

  @reason "the reason for the gap"

  # Note: technically, comparing Dates (and thus Datespans) using `==` is
  # a no-no. However, read the following as a mock-style expectation. Or
  # just that I'm too lazy to implement comparisons just for tests.
  
  describe "changeset successes" do
    test "parses iso strings" do
      changeset = ServiceGap.changeset(%ServiceGap{}, %{
            "start_date" => @iso_date, 
            "end_date" => @iso_later_date,
            "reason" => @reason})
      assert changeset.valid?
      assert changeset.changes.gap == Datespan.customary(@date, @later_date)
      assert changeset.changes.reason == @reason
    end

    test "handles 'never'" do
      changeset = ServiceGap.changeset(%ServiceGap{}, %{
            "start_date" => @iso_date, 
            "end_date" => "never",
            "reason" => @reason})
      assert changeset.valid?
      assert changeset.changes.gap == Datespan.infinite_up(@date, :inclusive)
      assert changeset.changes.reason == @reason
    end

    test "handles 'today'" do
      changeset = ServiceGap.changeset(%ServiceGap{}, %{
            "start_date" => "today", 
            "end_date" => "never",
            "reason" => @reason})
      assert changeset.valid?
      IO.puts("Say, did you know today is #{changeset.changes.gap.first}?")
      assert changeset.changes.reason == @reason
    end
  end

  describe "changeset errors" do
    test "format (should be impossible, but..." do
      changeset = ServiceGap.changeset(%ServiceGap{}, %{
            "start_date" => "bon", 
            "end_date" => "1990-02-31",
            "reason" => ""})
      refute changeset.valid?
      assert ServiceGap.parse_message in errors_on(changeset).start_date
      assert ServiceGap.parse_message in errors_on(changeset).end_date
      assert "can't be blank" in errors_on(changeset).reason
    end

    test "date mismatch (iso)" do
      changeset = ServiceGap.changeset(%ServiceGap{}, %{
            "start_date" => @iso_later_date,
            "end_date" => @iso_date,
            "reason" => @reason})
      refute changeset.valid?
      assert ServiceGap.order_message in errors_on(changeset).start_date
    end
  end
end
