defmodule Crit.Usables.FieldConverters.ToDateTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.Usables.FieldConverters.ToDate
  alias Pile.TimeHelper
  alias Ecto.Changeset
  alias Crit.Usables.Schemas.Animal

  # Assumes this partial schema. Fields are constant because they come from
  # the domain.
  
  embedded_schema do
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :timezone, :string
    
    field :in_service_date, :date
    field :out_of_service_date, :date
  end
  
  describe "basic conversions" do 
    test "explicit dates" do
      actual =
        [in_service_datestring: @iso_date,
         out_of_service_datestring: @later_iso_date]
        |> make_changeset_with_dates
        |> ToDate.put_service_dates__2
      
      assert actual.valid?
      assert actual.changes.in_service_date == @date
      assert actual.changes.out_of_service_date == @later_date
    end
    
    test "starting date is today" do
      actual =
        [in_service_datestring: @today,
         out_of_service_datestring: @later_iso_date]
        |> make_changeset_with_dates
        |> ToDate.put_service_dates__2
      
      today = TimeHelper.today_date(actual.changes.timezone)
      
      # Yes, this test will fail if it runs across a date boundary. So sue me.
      assert actual.valid?
      assert actual.changes.in_service_date == today
      assert actual.changes.out_of_service_date == @later_date
    end
    
    test "ending day is 'never', which marks the end date with a `nothing` value" do
      actual =
        [in_service_datestring: @iso_date,
         out_of_service_datestring: @never]
        |> make_changeset_with_dates
        |> ToDate.put_service_dates__2
      
      assert actual.valid?
      assert actual.changes.in_service_date == @date
      refute actual.changes[:out_of_service_date]
    end
    
    test "a supposedly impossible ill-formed date" do
      assert_raise RuntimeError, "Impossible input: invalid date `todays`", fn -> 
        [in_service_datestring: "todays", out_of_service_datestring: "Nev"]
        |> make_changeset_with_dates
        |> ToDate.put_service_dates__2
      end
    end
  end

  describe "cases where there's no change to a datestring" do
    test "in_service only" do
      actual =
        [in_service_datestring: @iso_date]
        |> make_changeset_with_dates
        |> ToDate.put_service_dates__2
      
      assert actual.valid?
      refute actual.changes[:out_of_service_date]
      assert actual.changes.in_service_date == @date
    end

    test "out_of_service only" do
      actual =
        [out_of_service_datestring: @later_iso_date]
        |> make_changeset_with_dates
        |> ToDate.put_service_dates__2
      
      assert actual.valid?
      refute actual.changes[:in_service_date]
      assert actual.changes.out_of_service_date == @later_date
    end
  end


  describe "misordering" do
    test "error case: dates are misordered" do
      errors =
        [in_service_datestring: @later_iso_date,
         out_of_service_datestring: @iso_date]
        |> make_changeset_with_dates
        |> ToDate.put_service_dates__2
        |> errors_on
      
      assert errors.out_of_service_datestring == [ToDate.misorder_error_message]
    end

    test "cannot set in-service date past an changed out-of-service-date" do
      first_iso_in_service = "2001-01-01"
      iso_out_of_service = "2002-02-02"
      bad_iso_in_service = "2003-03-03"

      animal = %Animal{
        in_service_datestring: first_iso_in_service,
        in_service_date: Date.from_iso8601!(first_iso_in_service),
        out_of_service_datestring: iso_out_of_service,
        out_of_service_date: Date.from_iso8601!(iso_out_of_service),
      }
      
      errors =
        [in_service_datestring: bad_iso_in_service]
        |> make_changeset_with_dates(animal)
        |> ToDate.put_service_dates__2
        |> errors_on
      
      assert errors.out_of_service_datestring == [ToDate.misorder_error_message]
    end

    test "cannot set out-of-service date before an in-service date" do
      bad_iso_out_of_service = "2001-01-01"
      iso_in_service = "2002-02-02"
      first_iso_out_of_service = "2003-03-03"

      animal = %Animal{
        in_service_datestring: iso_in_service,
        in_service_date: Date.from_iso8601!(iso_in_service),
        out_of_service_datestring: first_iso_out_of_service,
        out_of_service_date: Date.from_iso8601!(first_iso_out_of_service),
      }
      
      errors =
        [out_of_service_datestring: bad_iso_out_of_service]
        |> make_changeset_with_dates(animal)
        |> ToDate.put_service_dates__2
        |> errors_on
      
      assert errors.out_of_service_datestring == [ToDate.misorder_error_message]
    end
  end    

  def make_changeset_with_dates(date_opts, animal \\ %Animal{}) do
    default = %{timezone: "America/Chicago"}
    Changeset.change(animal, Enum.into(date_opts, default))
  end
end
