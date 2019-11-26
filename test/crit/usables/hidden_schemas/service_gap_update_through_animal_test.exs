defmodule Crit.Usables.HiddenSchemas.ServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal
  alias Crit.Usables.HiddenSchemas.ServiceGap
  import Crit.Usables.HiddenSchemas.ServiceGap, only: [span: 2]
  alias Crit.Usables.FieldConverters.ToDate
  alias Crit.Exemplars.Available
  alias Crit.Sql

  import Crit.Assertions.Changeset

  describe "date processing on update" do
    # processing of dates is independent of whether the dates are in the data
    # or in the attributes
    setup do
      attrs = attrs(@iso_date, @later_iso_date, "reason")
      insertion_result = insert(attrs)
      complete = get_and_complete(insertion_result.id)
      
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
      attrs = attrs(@iso_date, @iso_bumped_date, "reason", animal_id: animal_id)
      insertion_result = insert(attrs)
      original_gap = get_and_complete(insertion_result.id)
      complete_animal = AnimalApi.showable!(animal_id, @institution)
      
      [original_gap: original_gap, complete_animal: complete_animal]
    end

    setup :an_existing_animal_with_one_service_gap

    setup(%{original_gap: gap, complete_animal: animal}) do
      new_gap_params = %{in_service_date: @later_iso_date,
                         out_of_service_date: @later_iso_bumped_date,
                         reason: "addition"
                        }

      animal_update_attrs =
        same_animal_with_service_gap_params(animal, [
              form_params_for_existing(gap),
              new_gap_params
            ])

      [animal_attrs: animal_update_attrs]
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

  

  defp insert(attrs) do
    %ServiceGap{}
    |> ServiceGap.changeset(attrs)
    |> Sql.insert!(@institution)
  end

  defp get_and_complete(id) do
    ServiceGap
    |> Sql.get(id, @institution)
    |> ServiceGap.complete_fields
  end

  defp attrs(in_service_date, out_of_service_date, reason, opts \\ []) do
    defaults = %{animal_id: Available.animal_id}
    optmap = Enum.into(opts, defaults)
    %{animal_id: optmap.animal_id,
      in_service_date: in_service_date,
      out_of_service_date: out_of_service_date,
      reason: reason}
  end

  defp form_params_for_existing(service_gap) do 
    %{id: service_gap.id,
      in_service_date: service_gap.in_service_date,
      out_of_service_date: service_gap.out_of_service_date,
      reason: service_gap.reason}
  end


  defp same_animal_with_service_gap_params(animal, service_gaps) do
    IO.puts("TODO note: never")
    %{id: animal.id,
      name: animal.name,
      in_service_date: Date.to_iso8601(animal.in_service_date),
      # This will sometimes fail because the animal may have a "never"
      # out-of-service date.
      out_of_service_date: Date.to_iso8601(animal.out_of_service_date),
      lock_version: animal.lock_version,
      service_gaps: service_gaps
    }
  end
end
