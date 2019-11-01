defmodule Crit.Usables.HiddenSchemas.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.HiddenSchemas.ServiceGap
  alias Crit.Usables.FieldConverters.ToDate
  alias Ecto.Datespan
  alias Crit.Exemplars.Available


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

  describe "direct manipulation of changesets" do
    test "insertion" do
      animal_id = Available.animal_id
      attrs = %{animal_id: animal_id,
                in_service_date: @iso_date,
                out_of_service_date: @iso_date,
                reason: "reason"}
      # changeset = ServiceGap.changeset(%ServiceGap{}, attrs)
      # IO.inspect Sql.insert(changeset, @institution)
    end
  end

  describe "retrieval gaps are manipulated via animals" do
    # test "insertion" do
    #   animal = Minimal.animal
  end
  

  defp assert_span_has_not_been_added(%{changes: changes}), 
    do: refute changes[:span] 
  
end
