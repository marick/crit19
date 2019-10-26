defmodule Crit.Usables.FieldConverters.ToDateTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.FieldConverters.ToDate
  alias Pile.TimeHelper
  alias Ecto.Changeset

  # Assumes this partial schema. Fields are constant because they come from
  # the domain.
  
  embedded_schema do
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :timezone, :string
    
    field :in_service_date, :date
    field :out_of_service_date, :date
  end
  
  def make_changeset_with_dates(date_opts) do
    default = %{timezone: "America/Chicago"}
    Changeset.change(%__MODULE__{}, Enum.into(date_opts, default))
  end
  
  test "explicit dates" do
    actual =
      [in_service_datestring: @iso_date, out_of_service_datestring: @later_iso_date]
      |> make_changeset_with_dates
      |> ToDate.put_service_dates

      assert actual.valid?
      assert actual.changes.in_service_date == @date
      assert actual.changes.out_of_service_date == @later_date
  end

  test "starting date is today" do
    actual =
      [in_service_datestring: @today, out_of_service_datestring: @later_iso_date]
      |> make_changeset_with_dates
      |> ToDate.put_service_dates

    today = TimeHelper.today_date(actual.changes.timezone)
    
    # Yes, this test will fail if it runs across a date boundary. So sue me.
    assert actual.valid?
    assert actual.changes.in_service_date == today
    assert actual.changes.out_of_service_date == @later_date
  end

  test "ending day is 'never', which marks the end date with a `nothing` value" do
    actual =
      [in_service_datestring: @iso_date, out_of_service_datestring: @never]
      |> make_changeset_with_dates
      |> ToDate.put_service_dates

    assert actual.valid?
    assert actual.changes.in_service_date == @date
    refute actual.changes[:out_of_service_date]
  end

  test "error case: dates are misordered" do
    errors =
      [in_service_datestring: @later_iso_date, out_of_service_datestring: @iso_date]
      |> make_changeset_with_dates
      |> ToDate.put_service_dates
      |> errors_on

    assert errors.out_of_service_datestring == [ToDate.misorder_error_message]
  end

  test "a supposedly impossible ill-formed date" do

    assert_raise RuntimeError, "Impossible input: invalid date `todays`", fn -> 
      [in_service_datestring: "todays", out_of_service_datestring: "Nev"]
      |> make_changeset_with_dates
      |> ToDate.put_service_dates
    end
  end
end  
