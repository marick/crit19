defmodule Crit.Usables.HiddenSchemas.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.HiddenSchemas.ServiceGap
  alias Crit.Usables.FieldConverters.ToDate
  alias Ecto.Datespan
  alias Crit.Exemplars.Available
  alias Crit.Sql


  describe "changeset for insertion" do
    defp handle(attrs), do: ServiceGap.changeset(%ServiceGap{}, attrs)
    
    test "in- and out-of-service dates are converted..." do
      %{changes: changes} = changeset =
        handle(%{in_service_date: @iso_date,
                 out_of_service_date: @later_iso_date,
                 reason: "reason"})
      assert changeset.valid?
      assert changes.in_service_date == @date
      assert changes.out_of_service_date == @later_date
      assert changes.reason == "reason"
    end

    test "... span is set on success" do
      %{changes: changes} =
        handle(%{in_service_date: @iso_date,
                 out_of_service_date: @later_iso_date,
                 reason: "reason"})
      assert changes.span == Datespan.customary(@date, @later_date)
    end

    test "required fields are checked" do
      changeset = handle(%{})
      errors = errors_on(changeset)

      # Note that animal_id does not have to be present if we're always
      # manipulating service gaps via the animal they belong to.

      assert errors.in_service_date
      assert errors.out_of_service_date
      assert errors.reason
      assert_span_has_not_been_added(changeset)
    end

    test "dates must be in the right order" do
      %{changes: changes} = changeset =
        handle(%{in_service_date: @iso_date,
                 out_of_service_date: @iso_date,
                 reason: "reason"})
      refute changeset.valid?
      assert ToDate.misorder_error_message in errors_on(changeset).out_of_service_date
      assert changes.in_service_date == @date
      assert changes.out_of_service_date == @date
      assert changes.reason == "reason"
      assert_span_has_not_been_added(changeset)
    end
  end

  describe "direct manipulation of changesets: CREATE and READ" do
    setup do
      animal_id = Available.animal_id
      attrs = %{animal_id: animal_id,
                in_service_date: @iso_date,
                out_of_service_date: @later_iso_date,
                reason: "reason"}
      changeset = ServiceGap.changeset(%ServiceGap{}, attrs)

      {:ok, insertion_result} = Sql.insert(changeset, @institution)
      retrieved_gap = Sql.get(ServiceGap, insertion_result.id, @institution)

      
      [changeset: changeset, attrs: attrs, insertion_result: insertion_result,
       retrieved_gap: retrieved_gap]
    end
      
    test "insertion", %{insertion_result: result, attrs: attrs} do
      assert result.animal_id == attrs.animal_id
      assert result.span == Datespan.customary(@date, @later_date)
      assert result.reason == attrs.reason
      # We also get the virtual fields.
      # The date fields are converted, which is OK because EEX knows
      # how to convert them to ISO8601 strings in HTML.
      assert result.in_service_date == @date
      assert result.out_of_service_date == @later_date
    end

    test "fetching does not fill in virtual fields...",
      %{retrieved_gap: retrieved, attrs: attrs} do

      # We get the non-virtual fields
      assert retrieved.animal_id == attrs.animal_id
      assert retrieved.span == Datespan.customary(@date, @later_date)
      assert retrieved.reason == attrs.reason

      # but...
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
      assert complete.span == Datespan.customary(@date, @later_date)
      assert complete.reason == attrs.reason
    end
  end

  describe "date processing on update" do 
    # processing of dates is independent of whether the dates are in the data
    # or in the attributes
    @tag :skip
    test "error if in-service date is new"

    @tag :skip
    test "error if out-of-service date is new"

    @tag :skip 
    test "changed span if in-service date is new"

    @tag :skip 
    test "changed span if out-of-service date is new"

    @tag :skip 
    test "no span in changes if neither is new"
  end
  
  describe "retrieval gaps are manipulated via animals" do
    @tag :skip
    test "insertion"
  end
  

  defp assert_span_has_not_been_added(%{changes: changes}), 
    do: refute changes[:span] 
  
end
