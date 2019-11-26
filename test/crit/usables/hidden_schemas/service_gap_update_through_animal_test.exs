defmodule Crit.Usables.HiddenSchemas.ServiceGapUpdateThroughAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal
  alias Crit.Usables.HiddenSchemas.ServiceGap
  alias Crit.Usables.FieldConverters.ToDate
  alias Crit.Exemplars.Available
  alias Crit.Sql

  alias Crit.X.ServiceGapX
  alias Crit.X.AnimalX
  import Crit.Usables.HiddenSchemas.ServiceGap, only: [span: 2]

  import Crit.Assertions.Changeset

  describe "date processing on update" do
    # processing of dates is independent of whether the dates are in the data
    # or in the attributes
    setup do
      attrs = ServiceGapX.attrs(@iso_date, @later_iso_date, "reason")
      insertion_result = ServiceGapX.insert(attrs)
      complete = ServiceGapX.get_and_complete(insertion_result.id)
      
      [complete: complete, attrs: attrs]
    end

    test "Updating to all the same values", %{complete: complete, attrs: attrs} do
      ServiceGap.changeset(complete, attrs)
      |> assert_valid
      |> assert_unchanged
      # Implied by above, but let's be really explicit:
      |> assert_unchanged(:span)
    end

    test "the in-service date is new", %{complete: complete, attrs: attrs} do
      new_attrs = %{attrs | in_service_date: @iso_bumped_date}

      ServiceGap.changeset(complete, new_attrs)
      |> assert_valid
      |> assert_changes(in_service_date: @bumped_date,
                        span: span(@bumped_date, @later_date))

      |> assert_unchanged(:out_of_service_date)
    end


    test "out-of-service date is new", %{complete: complete, attrs: attrs} do
      new_attrs = %{attrs | out_of_service_date: @later_iso_bumped_date}

      
      ServiceGap.changeset(complete, new_attrs)
      |> assert_valid
      |> assert_changes(out_of_service_date: @later_bumped_date,
                        span: span(@date, @later_bumped_date))
      |> assert_unchanged(:in_service_date)
    end


    test "date mismatches are checked when just in_service date changes",
      %{complete: complete, attrs: attrs} do
      new_attrs = %{attrs | in_service_date: @later_iso_date}
      
      ServiceGap.changeset(complete, new_attrs)
      # Note that the error is always associated to the out-of-service error
      |> assert_error(out_of_service_date: ToDate.misorder_error_message)
      |> assert_change(in_service_date: @later_date)
      
      |> assert_unchanged([:out_of_service_date, :span])
    end

    test "date mismatches are checked when only out_of_service date changes",
      %{complete: complete, attrs: attrs} do
      new_attrs = %{attrs | out_of_service_date: @iso_date}
      
      ServiceGap.changeset(complete, new_attrs)
      |> assert_error(out_of_service_date: ToDate.misorder_error_message)
      |> assert_change(out_of_service_date: @date)
      
      |> assert_unchanged([:in_service_date, :span])
    end
  end
  
  describe "service gaps are manipulated via animals" do

    defp an_existing_animal_with_one_service_gap(_) do 
      animal_id = Available.animal_id
      attrs = ServiceGapX.attrs(@iso_date, @iso_bumped_date, "reason", animal_id: animal_id)
      insertion_result = ServiceGapX.insert(attrs)
      original_gap = ServiceGapX.get_and_complete(insertion_result.id)
      complete_animal = AnimalApi.showable!(animal_id, @institution)
      
      [original_gap: original_gap, complete_animal: complete_animal]
    end

    setup :an_existing_animal_with_one_service_gap

    setup(%{complete_animal: animal}) do
      new_gap = %{in_service_date: @later_iso_date,
                  out_of_service_date: @later_iso_bumped_date,
                  reason: "addition"
                 }
      [animal_attrs: AnimalX.attrs_plus_service_gap(animal, new_gap)]
    end
    
    test "What kind of changesets are produced by the `update_changeset`",
      %{complete_animal: complete_animal, animal_attrs: attrs} do

      [old_sg_changeset, new_sg_changeset] = 
        complete_animal
        |> Animal.update_changeset(attrs)
        |> (fn cs -> cs.changes.service_gaps end).()

      # No changes for the old service gap (therefore, it will not be UPDATED)
      old_sg_changeset |> assert_valid |> assert_unchanged

      # The new service gap, however, has a fleshed-out changeset
      new_sg_changeset
      |> assert_valid
      |> assert_changes(reason: "addition",
                        span: span(@later_date, @later_bumped_date))
    end

    test "the results of using the changeset",
      %{original_gap: original_gap, complete_animal: complete_animal, animal_attrs: attrs} do

      {:ok, %{service_gaps: [old, new]}} = 
        complete_animal
        |> Animal.update_changeset(attrs)
        |> Sql.update(@institution)

      assert old == original_gap
      
      assert is_integer(new.id)
      assert new.in_service_date == @later_date
      assert new.out_of_service_date == @later_bumped_date
      assert new.reason == "addition"
      assert new.span == span(@later_date, @later_bumped_date)
    end
  end
end
