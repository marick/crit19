defmodule Crit.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.ServiceGap
  alias Crit.Usables.ServiceGap.Multi
  alias Ecto.Datespan
  alias Pile.TimeHelper
  alias Crit.Sql

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2011-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

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

  describe "post_service_changeset" do
    test "unavailable as of a given date" do
      changeset = ServiceGap.post_service_changeset(
        %{"end_date" => @iso_date})
      assert changeset.valid?
      assert changeset.changes.gap == Datespan.infinite_up(@date, :inclusive)
      assert changeset.changes.reason == "animal taken out of service"
    end

    test "unavailable as of today (in institution's time zone)" do
      institution_timezone = "America/Chicago"
      
      changeset = ServiceGap.post_service_changeset(
        %{"end_date" => "today",
          "timezone" => institution_timezone
        },
        TimeHelper.stub_today_date(institution_timezone, to_return: @date))

      assert changeset.valid?
      assert changeset.changes.gap == Datespan.infinite_up(@date, :inclusive)
    end
  end

  describe "initial_changesets" do
    test "no end of service date" do 
      [in_service] = ServiceGap.initial_changesets(
        %{"start_date" => @iso_date,
          "end_date" => "never"
        })

      assert in_service.valid?
      assert in_service.changes.gap == Datespan.infinite_down(@date, :exclusive)
    end
    
    test "an end of service date" do 
      [in_service, out_of_service] = ServiceGap.initial_changesets(
        %{"start_date" => @iso_date,
          "end_date" => @later_iso_date
        })

      assert in_service.valid?
      assert in_service.changes.gap == Datespan.infinite_down(@date, :exclusive)

      assert out_of_service.valid?
      assert out_of_service.changes.gap == Datespan.infinite_up(@later_date, :inclusive)
    end

    test "misordered dates" do
      [in_service, out_of_service] = ServiceGap.initial_changesets(
        %{"start_date" => @later_iso_date,
          "end_date" => @iso_date,
        })

      assert in_service.valid?

      refute out_of_service.valid?
      assert ServiceGap.misorder_message in errors_on(out_of_service).end_date
    end


    test "no checking for misordered dates if start is invalid" do
      [in_service, out_of_service] = ServiceGap.initial_changesets(
        %{"start_date" => "broken",
          "end_date" => @iso_date,
        })

      refute in_service.valid?
      assert out_of_service.valid?
    end
    
    test "no checking for misordered dates if end is invalid" do
      [in_service, out_of_service] = ServiceGap.initial_changesets(
        %{"start_date" => @iso_date,
          "end_date" => "NEVER",
        })

      assert in_service.valid?
      refute out_of_service.valid?
    end
  end

  ## Initial service gaps

  describe "initial service gaps" do
    test "without an out-of-service date" do
      params = %{
        "start_date" => @iso_date,
        "end_date" => "never"
      }

      [inserted] =
        Multi.initial_service_gaps(params, @default_short_name)
        |> Sql.transaction(@default_short_name)
        |> result_gap_ids
        |> Enum.map(&inserted_gap/1)

      assert inserted.gap == Datespan.infinite_down(@date, :exclusive)
    end


    test "with an out-of-service date" do
      params = %{
        "start_date" => @iso_date,
        "end_date" => @later_iso_date
      }

      [before_service, after_service] =
        Multi.initial_service_gaps(params, @default_short_name)
        |> Sql.transaction(@default_short_name)
        |> result_gap_ids
        |> Enum.map(&inserted_gap/1)

      assert before_service.gap == Datespan.infinite_down(@date, :exclusive)
      assert after_service.gap == Datespan.infinite_up(@later_date, :inclusive)
    end

    test "date order error produces a changeset" do
      params = %{
        "start_date" => "fkj", #@later_iso_date,
        "end_date" => "kkks" #@iso_date
      }

      result = 
        Multi.initial_service_gaps(params, @default_short_name)
        |> Sql.transaction(@default_short_name)
        |> IO.inspect

      # refute changeset.valid?
      # assert ServiceGap.misorder_message in errors_on(changeset).end_date
    end
    
  end

  def result_gap_ids({:ok, %{gap_ids: gap_ids}}), do: gap_ids

  def inserted_gap(gap_id),
    do: Sql.get(ServiceGap, gap_id, @default_short_name)
end
