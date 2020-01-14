defmodule Crit.Usables.Schemas.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.ServiceGap
  alias Crit.Sql

  alias Ecto.Datespan
  alias Crit.Extras.ServiceGapT

  import Crit.Assertions.Changeset

  describe "changeset for insertion" do
    defp handle(attrs), do: ServiceGap.changeset(%ServiceGap{}, attrs)
    
    test "all three values are valid" do
      given = %{in_service_datestring: @iso_date,
                out_of_service_datestring: @later_iso_date,
                institution: @institution,
                reason: "reason"}
      
      handle(given)
      |> assert_valid
      |> assert_changes(in_service_datestring: @iso_date,
                        out_of_service_datestring: @later_iso_date,
                        reason: "reason",
                        # And the span is created
                        span: Datespan.customary(@date, @later_date))
    end
    

    # Error checking

    test "required fields are must be present" do
      # Note that animal_id does not have to be present if we're always
      # manipulating service gaps via the animal they belong to.

      handle(%{})
      |> assert_errors([:in_service_datestring, :out_of_service_datestring, :reason])
      |> assert_unchanged(:span)
    end

    test "dates must be in the right order" do
      given = %{in_service_datestring: @iso_date,
                out_of_service_datestring: @iso_date,
                institution: @institution,
                reason: "reason"}
      handle(given)
      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_unchanged(:span)

      # Other fields are available to fill form fields
      |> assert_changes(in_service_datestring: @iso_date,
                        out_of_service_datestring: @iso_date,
                        reason: "reason")
    end
  end

  describe "direct manipulation of changesets: CREATE and READ" do
    setup do
      attrs = ServiceGapT.attrs(@iso_date, @later_iso_date, "reason")
      insertion_result = ServiceGapT.insert(attrs)
      retrieved_gap = Sql.get(ServiceGap, insertion_result.id, @institution)
      [attrs: attrs, insertion_result: insertion_result, retrieved_gap: retrieved_gap]
    end
      
    test "insertion", %{insertion_result: result, attrs: attrs} do
      assert result.animal_id == attrs.animal_id
      assert result.span == Datespan.customary(@date, @later_date)

      assert result.reason == attrs.reason
      # We also get the virtual fields.
      # The date fields are converted, which is OK because EEX knows
      # how to convert them to ISO8601 strings for the HTML.
      assert result.in_service_datestring == @iso_date
      assert result.out_of_service_datestring == @later_iso_date
    end

    test "`Sql.get` does not fill in virtual fields...",
      %{retrieved_gap: retrieved, attrs: attrs} do

      # We get the non-virtual fields
      assert retrieved.animal_id == attrs.animal_id
      assert retrieved.span == Datespan.customary(@date, @later_date)
      assert retrieved.reason == attrs.reason

      # but not the virtual ones
      refute retrieved.in_service_datestring
      refute retrieved.out_of_service_datestring
    end

    test "... so there's a function for that",
      %{retrieved_gap: retrieved, attrs: attrs} do
      updatable = ServiceGap.put_updatable_fields(retrieved, @institution)

      assert updatable.in_service_datestring == @iso_date
      assert updatable.out_of_service_datestring == @later_iso_date
      assert updatable.institution == @institution

      # And other fields are still there
      assert updatable.animal_id == attrs.animal_id
      assert updatable.span == Datespan.customary(@date, @later_date)
      assert updatable.reason == attrs.reason
    end
  end

  describe "behavior of `changeset` given an existing service gap" do
    # processing of dates is independent of whether the dates are in the data
    # or in the attributes
    setup do
      attrs = ServiceGapT.attrs(@iso_date, @later_iso_date, "reason")
      insertion_result = ServiceGapT.insert(attrs)
      updatable = ServiceGapT.get_updatable(insertion_result.id)
      
      [updatable: updatable, attrs: attrs]
    end

    test "Updating to all the same values", %{updatable: updatable, attrs: attrs} do
      ServiceGap.changeset(updatable, attrs)
      |> assert_valid
      |> assert_unchanged([:span, :in_service_datestring, :out_of_service_datestring])
    end

    test "the in-service date is new", %{updatable: updatable, attrs: attrs} do
      new_attrs = %{attrs | in_service_datestring: @iso_bumped_date}

      ServiceGap.changeset(updatable, new_attrs)
      |> assert_valid
      |> assert_changes(in_service_datestring: @iso_bumped_date,
                        span: Datespan.customary(@bumped_date, @later_date))

      |> assert_unchanged(:out_of_service_datestring)
    end


    test "out-of-service date is new", %{updatable: updatable, attrs: attrs} do
      new_attrs = %{attrs | out_of_service_datestring: @later_iso_bumped_date}

      
      ServiceGap.changeset(updatable, new_attrs)
      |> assert_valid
      |> assert_changes(out_of_service_datestring: @later_iso_bumped_date,
                        span: Datespan.customary(@date, @later_bumped_date))
      |> assert_unchanged(:in_service_datestring)
    end


    test "date mismatches are checked when just in_service date changes",
      %{updatable: updatable, attrs: attrs} do
      new_attrs = %{attrs | in_service_datestring: @later_iso_date}
      
      ServiceGap.changeset(updatable, new_attrs)
      # Note that the error is always associated to the out-of-service error
      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_change(in_service_datestring: @later_iso_date)
      
      |> assert_unchanged([:out_of_service_datestring, :span])
    end

    test "date mismatches are checked when only out_of_service date changes",
      %{updatable: updatable, attrs: attrs} do
      new_attrs = %{attrs | out_of_service_datestring: @iso_date}
      
      ServiceGap.changeset(updatable, new_attrs)
      |> assert_error(out_of_service_datestring: @date_misorder_message)
      |> assert_change(out_of_service_datestring: @iso_date)
      
      |> assert_unchanged([:in_service_datestring, :span])
    end

    test "set action to `:delete` if `delete` field is set",
      %{updatable: updatable, attrs: attrs} do

      new_attrs = %{attrs | delete: true}
      
      ServiceGap.changeset(updatable, new_attrs)
      |> assert_field(action: :delete)
    end
  end
end
