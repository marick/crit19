defmodule Crit.FieldConverters.ToSpanTest do
  use Ecto.Schema
  use Crit.DataCase
  alias Crit.FieldConverters.ToSpan
  alias Pile.TimeHelper
  alias Ecto.Changeset
  alias Ecto.Datespan
  alias Crit.Setup.InstitutionApi

  # Assumes this partial schema. 
  # Various constants are reasonably stable, given the domain.
  
  embedded_schema do
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :institution, :string
    
    field :span, Datespan
  end

  @timezone "America/Los_Angeles"

  describe "cases where there's no upper bound" do
    test "a valid in-service date" do
      make_changeset(in_service_datestring: @iso_date,
                     out_of_service_datestring: @never,
                     institution: "--irrelevant--")
      |> assert_valid
      |> assert_change(span: Datespan.inclusive_up(@date))
    end

    test "the special value `today`" do
      assert InstitutionApi.timezone(@institution) == @timezone
      # above makes sure that timezone is as expected
      today_date = TimeHelper.today_date(@timezone)

      make_changeset(in_service_datestring: @today,
                     out_of_service_datestring: @never,
                     institution: @institution)

      |> assert_valid
      |> assert_change(span: Datespan.inclusive_up(today_date))
    end
    
    test "a invalid in-service date" do
      make_changeset(in_service_datestring: "2013-13-13",
                     out_of_service_datestring: @never,
                     institution: "--irrelevant--")
      |> assert_invalid
      |> assert_error(in_service_datestring: "is invalid")
      |> assert_error_free(:out_of_service_datestring)
      |> assert_unchanged(:span)
    end

    test "it is invalid to use `never` as a start date" do
      make_changeset(in_service_datestring: @never,
                     out_of_service_datestring: @never,
                     institution: "--irrelevant--")

      |> assert_invalid
      |> assert_error(in_service_datestring: ~S{"must be a date or "today"})
      |> assert_error_free(:out_of_service_datestring)
      |> assert_unchanged(:span)
    end
  end

  describe "cases where there IS an upper bound" do
    test "a valid in-service date" do
      make_changeset(in_service_datestring: @iso_date,
                     out_of_service_datestring: @later_iso_date,
                     institution: "--irrelevant--")

      |> assert_valid
      |> assert_change(span: Datespan.customary(@date, @later_date))
    end

    test "both dates are invalid" do
      make_changeset(in_service_datestring: "todaync",
                     out_of_service_datestring: "nev",
                     institution: "--irrelevant--")
      |> assert_invalid
      |> assert_error(in_service_datestring: "is invalid",
                      out_of_service_datestring: "is invalid")
      |> assert_unchanged(:span)
    end

    test "just the upper bound is invalid" do
      make_changeset(in_service_datestring: "today",
                     out_of_service_datestring: "nev",
                     institution: @institution)
      |> assert_invalid
      |> assert_error(out_of_service_datestring: "is invalid")
      |> assert_error_free(:in_service_datestring)
      |> assert_unchanged(:span)
    end
  end

  describe "checking for misordering" do
    # That checks are only made if there are no previous errors
    # is implied by the fact that previous tests don't blow up.
    test "both values are valid" do
      make_changeset(in_service_datestring: @later_iso_date,
                     out_of_service_datestring: @iso_date,
                     institution: "--irrelevant--")

      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_error_free(:in_service_datestring)
      |> assert_unchanged(:span)
    end

    test "the bounds of equality" do
      make_changeset(in_service_datestring: @iso_date,
                     out_of_service_datestring: @iso_date,
                     institution: "--irrelevant--")

      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_error_free(:in_service_datestring)
      |> assert_unchanged(:span)
    end
  end

  describe "workings when some of the data is not from a change" do
    test "there is backing data, and one field differs" do
      original = %__MODULE__{
        in_service_datestring: @iso_date,
        out_of_service_datestring: @never,
        institution: "--irrelevant--",
        span: Datespan.inclusive_up(@date)
      }

      make_changeset(original, in_service_datestring: @iso_date,
                               out_of_service_datestring: @later_iso_date,
                               institution: "--irrelevant--")
      |> assert_valid
      |> assert_change(span: Datespan.customary(@date, @later_date))
    end

    test "error case for backing data" do
      original = %__MODULE__{
        in_service_datestring: @iso_date,
        out_of_service_datestring: @later_iso_date,
        institution: "--irrelevant--",
        span: Datespan.customary(@date, @later_date)
      }

      make_changeset(original, in_service_datestring: @iso_date,
                               out_of_service_datestring: @iso_date,
                               institution: "--irrelevant--")
      |> assert_invalid
      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_unchanged(:span)
    end

    test "if there is no change, the span will not be redundantly written" do
      original = %__MODULE__{
        in_service_datestring: @iso_date,
        out_of_service_datestring: @later_iso_date,
        institution: "--irrelevant--",
        
        span: Datespan.customary(@date, @later_date)
      }

      make_changeset(original, in_service_datestring: @iso_date,
                               out_of_service_datestring: @later_iso_date,
                               institution: "--irrelevant--")

      |> assert_valid
      |> assert_unchanged([:in_service_datestring, :out_of_service_datestring,
                           :span])
    end

    test "a blank out_of_service field cannot lead to a crash" do
      # If a field is blank, `validate_required` will delete it from `changes`.
      # That used to lead to trying to parse `nil` as a date.
      # Note that the user will get two messages, but they're clear enough.
      # Also the user is supposed to be using a date-picker.
      date_opts = %{
        in_service_datestring: @iso_date,
        out_of_service_datestring: " ",
        institution: "--irrelevant--"
      }

      %__MODULE__{}
      |> ToSpan.synthesize(date_opts)
      |> assert_invalid
      |> assert_errors(out_of_service_datestring:
           ["is invalid", "can't be blank"])
      |> assert_error_free(:in_service_datestring)
      |> assert_unchanged(:span)
    end


    test "a blank in_service field cannot lead to a crash" do
      date_opts = %{
        in_service_datestring: " ",
        out_of_service_datestring: @iso_date,
        institution: "--irrelevant--"
      }

      %__MODULE__{}
      |> ToSpan.synthesize(date_opts)
      |> assert_invalid
      |> assert_errors(in_service_datestring: "can't be blank")
      |> assert_error_free(:out_of_service_datestring)
      |> assert_unchanged(:span)
    end
    
  end

  defp make_changeset(date_opts),
    do: make_changeset(%__MODULE__{}, date_opts)

  defp make_changeset(previous, date_opts) do 
    Changeset.change(previous, Enum.into(date_opts, %{}))
    |> ToSpan.synthesize
  end
end
