defmodule Crit.Usables.Internal.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.ServiceGap
  alias Crit.Global
  alias Pile.TimeHelper

  describe "pre_service_changeset" do
    test "starts on a given date" do
      changeset = ServiceGap.pre_service_changeset(
        %{"start_date" => @iso_date})
      assert changeset.valid?
      assert_strictly_before(changeset.changes.gap, @date)
      assert changeset.changes.reason == "before animal was put in service"
    end

    test "starts today (in institution's time zone)" do
      institution_timezone = Global.timezone(@institution)
      
      changeset = ServiceGap.pre_service_changeset(
        %{"start_date" => @today,
          "timezone" => institution_timezone
        },
        TimeHelper.stub_today_date(institution_timezone, to_return: @date))

      assert changeset.valid?
      assert_strictly_before(changeset.changes.gap, @date)
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
      assert_date_and_after(changeset.changes.gap, @date)
      assert changeset.changes.reason == "animal taken out of service"
    end

    test "unavailable as of today (in institution's time zone)" do
      institution_timezone = Global.timezone(@institution)
      
      changeset = ServiceGap.post_service_changeset(
        %{"end_date" => @today,
          "timezone" => institution_timezone
        },
        TimeHelper.stub_today_date(institution_timezone, to_return: @date))

      assert changeset.valid?
      assert_date_and_after(changeset.changes.gap, @date)
    end
  end

  describe "initial_changesets" do
    test "no end of service date" do 
      {:ok, [in_service]} = ServiceGap.initial_changesets(
        %{"start_date" => @iso_date,
          "end_date" => @never
        })

      assert in_service.valid?
      assert_strictly_before(in_service.changes.gap, @date)
    end
    
    test "an end of service date" do 
      {:ok, [in_service, out_of_service]} = ServiceGap.initial_changesets(
        %{"start_date" => @iso_date,
          "end_date" => @later_iso_date
        })

      assert in_service.valid?
      assert_strictly_before(in_service.changes.gap, @date)

      assert out_of_service.valid?
      assert_date_and_after(out_of_service.changes.gap, @later_date)
    end

    test "misordered dates" do
      {:error, changeset} = ServiceGap.initial_changesets(
        %{"start_date" => @later_iso_date,
          "end_date" => @iso_date,
        })

      refute changeset.valid?
      assert ServiceGap.misorder_message in errors_on(changeset).end_date
    end

    test "no checking for misordered dates if start is invalid" do
      {:error, changeset} = ServiceGap.initial_changesets(
        %{"start_date" => "broken",
          "end_date" => @iso_date,
        })

      refute changeset.valid?
      assert ServiceGap.parse_message in errors_on(changeset).start_date
    end

    test "no checking for misordered dates if end is invalid" do
      {:error, changeset} = ServiceGap.initial_changesets(
        %{"start_date" => @iso_date,
          "end_date" => "not ever",
        })

      refute changeset.valid?
      assert ServiceGap.parse_message in errors_on(changeset).end_date
    end

    test "errors are merged" do
      {:error, changeset} = ServiceGap.initial_changesets(
        %{"start_date" => "busted",
          "end_date" => "NEER",
        })

      refute changeset.valid?
      assert ServiceGap.parse_message in errors_on(changeset).start_date
      assert ServiceGap.parse_message in errors_on(changeset).end_date
    end
  end
end
