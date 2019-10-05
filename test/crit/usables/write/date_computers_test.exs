defmodule Crit.Usables.Write.DateComputersTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.Write.DateComputers
  alias Pile.TimeHelper
  alias Ecto.Changeset

  # This is the subset of the Read.Animal schema that `DateComputers` operates on.
  embedded_schema do
    field :start_date, :string
    field :end_date, :string
    field :timezone, :string

    field :computed_start_date, :date, virtual: true
    field :computed_end_date, :date, virtual: true
  end
  
  def make_changeset_with_dates(date_opts) do
    default = %{timezone: "America/Chicago"}
    Changeset.change(%__MODULE__{}, Enum.into(date_opts, default))
  end
  
  test "explicit dates" do
    actual =
      [start_date: @iso_date, end_date: @later_iso_date]
      |> make_changeset_with_dates
      |> DateComputers.put_start_and_end

      assert actual.valid?
      assert actual.changes.computed_start_date == @date
      assert actual.changes.computed_end_date == @later_date
  end

  test "starting date is today" do
    actual =
      [start_date: @today, end_date: @later_iso_date]
      |> make_changeset_with_dates
      |> DateComputers.put_start_and_end

    today = TimeHelper.today_date(actual.changes.timezone)
    
    # Yes, this test will fail if it runs across a date boundary. So sue me.
    assert actual.valid?
    assert actual.changes.computed_start_date == today
    assert actual.changes.computed_end_date == @later_date
  end

  test "ending day is 'never', which marks the end date with a `nothing` value" do
    actual =
      [start_date: @iso_date, end_date: @never]
      |> make_changeset_with_dates
      |> DateComputers.put_start_and_end

    assert actual.valid?
    assert actual.changes.computed_start_date == @date
    assert actual.changes.computed_end_date == :missing
  end

  test "error case: dates are misordered" do
    errors =
      [start_date: @later_iso_date, end_date: @iso_date]
      |> make_changeset_with_dates
      |> DateComputers.put_start_and_end
      |> errors_on

    assert errors.end_date == [DateComputers.misorder_error_message]
  end

  test "a supposedly impossible ill-formed date" do

    assert_raise RuntimeError, "Impossible input: invalid date `todays`", fn -> 
      [start_date: "todays", end_date: "Nev"]
      |> make_changeset_with_dates
      |> DateComputers.put_start_and_end
    end
  end
end  
