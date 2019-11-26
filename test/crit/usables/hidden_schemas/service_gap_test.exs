defmodule Crit.Usables.HiddenSchemas.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.HiddenSchemas.ServiceGap
  alias Crit.Usables.FieldConverters.ToDate
  alias Crit.Sql

  alias Crit.X.ServiceGapX
  import Crit.Usables.HiddenSchemas.ServiceGap, only: [span: 2]

  import Crit.Assertions.Changeset

  describe "changeset for insertion" do
    defp handle(attrs), do: ServiceGap.changeset(%ServiceGap{}, attrs)
    
    test "all three values are valid" do
      given = %{in_service_date: @iso_date,
                out_of_service_date: @later_iso_date,
                reason: "reason"}
      
      handle(given)
      |> assert_valid
      |> assert_changes(in_service_date: @date,
                        out_of_service_date: @later_date,
                        reason: "reason",
                        # And the span is created
                        span: span(@date, @later_date))
    end
    

    # Error checking

    test "required fields are checked" do
      # Note that animal_id does not have to be present if we're always
      # manipulating service gaps via the animal they belong to.

      handle(%{})
      |> assert_errors([:in_service_date, :out_of_service_date, :reason])
      |> assert_unchanged(:span)
    end

    test "dates must be in the right order" do
      given = %{in_service_date: @iso_date,
                out_of_service_date: @iso_date,
                reason: "reason"}
      handle(given)
      |> assert_error(out_of_service_date: ToDate.misorder_error_message)
      |> assert_unchanged(:span)

      # Other fields are available to fill form fields
      |> assert_changes(in_service_date: @date,
                        out_of_service_date: @date,
                        reason: "reason")
    end
  end

  describe "direct manipulation of changesets: CREATE and READ" do
    setup do
      attrs = ServiceGapX.attrs(@iso_date, @later_iso_date, "reason")
      insertion_result = ServiceGapX.insert(attrs)
      retrieved_gap = Sql.get(ServiceGap, insertion_result.id, @institution)
      [attrs: attrs, insertion_result: insertion_result, retrieved_gap: retrieved_gap]
    end
      
    test "insertion", %{insertion_result: result, attrs: attrs} do
      assert result.animal_id == attrs.animal_id
      assert result.span == span(@date, @later_date)
      assert result.reason == attrs.reason
      # We also get the virtual fields.
      # The date fields are converted, which is OK because EEX knows
      # how to convert them to ISO8601 strings for the HTML.
      assert result.in_service_date == @date
      assert result.out_of_service_date == @later_date
    end

    test "`Sql.get` does not fill in virtual fields...",
      %{retrieved_gap: retrieved, attrs: attrs} do

      # We get the non-virtual fields
      assert retrieved.animal_id == attrs.animal_id
      assert retrieved.span == span(@date, @later_date)
      assert retrieved.reason == attrs.reason

      # but not the virtual ones
      refute retrieved.in_service_date
      refute retrieved.out_of_service_date
    end

    test "... so there's a function for that",
      %{retrieved_gap: retrieved, attrs: attrs} do
      complete = ServiceGap.complete_fields(retrieved)

      assert complete.in_service_date == @date
      assert complete.out_of_service_date == @later_date

      # And other fields are still there
      assert complete.animal_id == attrs.animal_id
      assert complete.span == span(@date, @later_date)
      assert complete.reason == attrs.reason
    end
  end
end
