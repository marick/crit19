defmodule Crit.Usables.FieldConverters.ToDateTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.FieldConverters.ToDate
  alias Pile.TimeHelper
  alias Ecto.Changeset

  # This is the subset of the Read.Animal schema that `ToDate` operates on.
  embedded_schema do
    field :in_service_date, :string
    field :out_of_service_date, :string
    field :timezone, :string

    field :computed_in_service_date, :date, virtual: true
    field :computed_out_of_service_date, :date, virtual: true
  end
  
  def make_changeset_with_dates(date_opts) do
    default = %{timezone: "America/Chicago"}
    Changeset.change(%__MODULE__{}, Enum.into(date_opts, default))
  end
  
  test "explicit dates" do
    actual =
      [in_service_date: @iso_date, out_of_service_date: @later_iso_date]
      |> make_changeset_with_dates
      |> ToDate.put_start_and_end

      assert actual.valid?
      assert actual.changes.computed_in_service_date == @date
      assert actual.changes.computed_out_of_service_date == @later_date
  end

  test "starting date is today" do
    actual =
      [in_service_date: @today, out_of_service_date: @later_iso_date]
      |> make_changeset_with_dates
      |> ToDate.put_start_and_end

    today = TimeHelper.today_date(actual.changes.timezone)
    
    # Yes, this test will fail if it runs across a date boundary. So sue me.
    assert actual.valid?
    assert actual.changes.computed_in_service_date == today
    assert actual.changes.computed_out_of_service_date == @later_date
  end

  test "ending day is 'never', which marks the end date with a `nothing` value" do
    actual =
      [in_service_date: @iso_date, out_of_service_date: @never]
      |> make_changeset_with_dates
      |> ToDate.put_start_and_end

    assert actual.valid?
    assert actual.changes.computed_in_service_date == @date
    assert actual.changes.computed_out_of_service_date == :missing
  end

  test "error case: dates are misordered" do
    errors =
      [in_service_date: @later_iso_date, out_of_service_date: @iso_date]
      |> make_changeset_with_dates
      |> ToDate.put_start_and_end
      |> errors_on

    assert errors.out_of_service_date == [ToDate.misorder_error_message]
  end

  test "a supposedly impossible ill-formed date" do

    assert_raise RuntimeError, "Impossible input: invalid date `todays`", fn -> 
      [in_service_date: "todays", out_of_service_date: "Nev"]
      |> make_changeset_with_dates
      |> ToDate.put_start_and_end
    end
  end
end  
