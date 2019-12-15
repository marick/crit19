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

  @timezone "America/Chicago"

  describe "basic conversions of date parameters" do
    test "explicit dates" do
      make_changeset(in_service_datestring: @iso_date,
                     out_of_service_datestring: @later_iso_date)
      |> assert_valid
      |> assert_changes(in_service_date: @date,
                        out_of_service_date: @later_date)
    end
    
    test "starting date is today" do
      # Yes, this test will fail if it runs across a date boundary. So sue me.
      today = TimeHelper.today_date(@timezone)
      
      make_changeset(in_service_datestring: @today,
                     out_of_service_datestring: @later_iso_date)
      |> assert_valid
      |> assert_changes(in_service_date: today,
                        out_of_service_date: @later_date)
    end
    
    test "ending day is 'never'" do
      make_changeset(in_service_datestring: @iso_date,
                     out_of_service_datestring: @never)
      |> assert_valid
      |> assert_changes(in_service_date: @date)
         # Assumes the schema's default value means "never"
      |> assert_unchanged(:out_of_service_date)
    end
    
    test "a supposedly impossible ill-formed date" do
      assert_raise RuntimeError, "Impossible input: invalid date `todays`", fn -> 
        make_changeset(in_service_datestring: "todays",
                       out_of_service_datestring: "Nev")
      end
    end
  end

  describe "misordering without existing `data` values (creation)" do
    test "error case: dates are misordered" do
      make_changeset(in_service_datestring: @later_iso_date,
                     out_of_service_datestring: @iso_date)
      |> assert_error(out_of_service_datestring: ToDate.misorder_error_message)
    end
  end

  describe "misordering with existing `data` values (updating)" do
    test "new in-service date is AFTER existing out-of-service date" do
      assert_introduced_misorder({"2002-02-02", "2003-03-03"},
        in_service_datestring:                  "3333-01-01")
    end

    test "new out-of-service date is BEFORE existing in-service date" do
      assert_introduced_misorder( {"2002-02-02", "2003-03-03"},
        out_of_service_datestring: "1900-01-01")
    end

    test "there is no out-of-service date, so no possibility of misorder" do
      make_changeset({    @later_iso_date, @never},
         in_service_datestring: @iso_date)
      |> assert_valid
      |> assert_change(in_service_date: @date)
      |> assert_unchanged(:out_of_service_date)
    end
  end

  defp make_changeset(date_opts), do: make_changeset(%Animal{}, date_opts)

  defp make_changeset({iso_in_service, iso_out_of_service}, date_opts) do
    out_of_service = if iso_out_of_service == @never do
      nil
    else
      Date.from_iso8601!(iso_out_of_service)
    end
    
    animal = %Animal{
        in_service_datestring: iso_in_service,
        in_service_date: Date.from_iso8601!(iso_in_service),
        out_of_service_datestring: iso_out_of_service,
        out_of_service_date: out_of_service
    }
    make_changeset(animal, date_opts)
  end

  defp make_changeset(animal, date_opts) do
    default = %{timezone: @timezone}
    Changeset.change(animal, Enum.into(date_opts, default))
    |> ToDate.put_service_dates
  end

  defp assert_introduced_misorder(existing, date_opts) do
    make_changeset(existing, date_opts)
    |> assert_error(out_of_service_datestring: ToDate.misorder_error_message)
  end
end
