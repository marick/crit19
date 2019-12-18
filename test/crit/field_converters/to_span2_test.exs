defmodule Crit.FieldConverters.ToSpan2Test do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.FieldConverters.ToSpan2, as: ToSpan
  alias Pile.TimeHelper
  alias Ecto.Changeset
  alias Ecto.Datespan

  # Assumes this partial schema. 
  # Various constants are reasonably stable, given the domain.
  
  embedded_schema do
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :timezone, :string
    
    field :span, Datespan
  end

  @timezone "America/Chicago"

  describe "cases where there's no upper bound" do
    test "a valid in-service date" do
      make_changeset(in_service_datestring: @iso_date,
                     out_of_service_datestring: @never)
      |> assert_valid
      |> assert_change(span: Datespan.infinite_up(@date, :inclusive))
    end

    test "the special value `today`" do
      today_date = TimeHelper.today_date(@timezone)

      make_changeset(in_service_datestring: @today,
                     out_of_service_datestring: @never)
      |> assert_valid
      |> assert_change(span: Datespan.infinite_up(today_date, :inclusive))
    end
    
    test "a invalid in-service date" do
      make_changeset(in_service_datestring: "2013-13-13",
                     out_of_service_datestring: @never)
      |> assert_invalid
      |> assert_error(in_service_datestring: "is invalid")
      |> assert_error_free(:out_of_service_datestring)
    end

    test "it is invalid to use `never` as a start date" do
      make_changeset(in_service_datestring: @never,
                     out_of_service_datestring: @never)
      |> assert_invalid
      |> assert_error(in_service_datestring: ~S{"must be a date or "today"})
      |> assert_error_free(:out_of_service_datestring)
    end
  end

  describe "cases where there IS an upper bound" do
    test "a valid in-service date" do
      make_changeset(in_service_datestring: @iso_date,
                     out_of_service_datestring: @later_iso_date)
      |> assert_valid
      |> assert_change(span: Datespan.customary(@date, @later_date))
    end

    test "both dates are invalid" do
      make_changeset(in_service_datestring: "todaync",
                     out_of_service_datestring: "nev")
      |> assert_invalid
      |> assert_error(in_service_datestring: "is invalid",
                      out_of_service_datestring: "is invalid")
    end

    test "just the upper bound is invalid" do
      make_changeset(in_service_datestring: "today",
                     out_of_service_datestring: "nev")
      |> assert_invalid
      |> assert_error(out_of_service_datestring: "is invalid")
      |> assert_error_free(:in_service_datestring)
    end
  end

  describe "checking for misordering" do
    # That checks are only made if there are no previous errors
    # is implied by the fact that previous tests don't blow up.
    test "both values are valid" do
      make_changeset(in_service_datestring: @later_iso_date,
                     out_of_service_datestring: @iso_date)
      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_error_free(:in_service_datestring)
    end

    test "the bounds of equality" do
      make_changeset(in_service_datestring: @iso_date,
                     out_of_service_datestring: @iso_date)
      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_error_free(:in_service_datestring)
    end
  end

  describe "workings when some of the data is not from a change" do
    test "there is backing data, and one field differs" do
      original = %__MODULE__{
        in_service_datestring: @iso_date,
        out_of_service_datestring: @never,
        span: Datespan.infinite_up(@date, :inclusive)
      }

      make_changeset(original, in_service_datestring: @iso_date,
                               out_of_service_datestring: @later_iso_date)
      |> assert_valid
      |> assert_change(span: Datespan.customary(@date, @later_date))
    end

    test "error case for backing data" do
      original = %__MODULE__{
        in_service_datestring: @iso_date,
        out_of_service_datestring: @later_iso_date,
        span: Datespan.customary(@date, @later_date)
      }

      make_changeset(original, in_service_datestring: @iso_date,
                               out_of_service_datestring: @iso_date)
      |> assert_invalid
      |> assert_error(out_of_service_datestring: @date_misorder_message)
    end

    test "if there is no change, the span will not be redundantly written" do
      original = %__MODULE__{
        in_service_datestring: @iso_date,
        out_of_service_datestring: @later_iso_date,
        span: Datespan.customary(@date, @later_date)
      }

      make_changeset(original, in_service_datestring: @iso_date,
                               out_of_service_datestring: @later_iso_date)
      |> assert_valid
      |> assert_unchanged([:in_service_datestring, :out_of_service_datestring,
                           :span])
    end
  end

  defp make_changeset(date_opts),
    do: make_changeset(%__MODULE__{}, date_opts)

  defp make_changeset(previous, date_opts) do 
    default = %{timezone: @timezone}
    Changeset.change(previous, Enum.into(date_opts, default))
    |> ToSpan.synthesize
  end
end
