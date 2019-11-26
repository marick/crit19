defmodule Crit.Usables.HiddenSchemas.ServiceGapUpdateThroughAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal
  # alias Crit.Usables.HiddenSchemas.ServiceGap
  alias Crit.Exemplars.Available
  alias Crit.Sql

  alias Crit.X.ServiceGapX
  alias Crit.X.AnimalX
  import Crit.Usables.HiddenSchemas.ServiceGap, only: [span: 2]

  import Crit.Assertions.Changeset

  
  describe "adding a service gap" do
    setup :an_existing_animal_with_one_service_gap

    setup(%{complete_animal: animal}) do
      new_gap = %{in_service_date: @later_iso_date,
                  out_of_service_date: @later_iso_bumped_date,
                  reason: "addition"
                 }
      [animal_attrs: AnimalX.attrs_plus_service_gap(animal, new_gap)]
    end
    
    test "What kind of service gap changesets are produced by `Animal.update_changeset`",
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
      %{complete_animal: complete_animal, animal_attrs: attrs} do

      {:ok, %{service_gaps: [old, new]}} = 
        complete_animal
        |> Animal.update_changeset(attrs)
        |> Sql.update(@institution)
      
      assert old == original_gap(complete_animal)
      
      assert is_integer(new.id)
      assert new.in_service_date == @later_date
      assert new.out_of_service_date == @later_bumped_date
      assert new.reason == "addition"
      assert new.span == span(@later_date, @later_bumped_date)
    end
  end

  defp an_existing_animal_with_one_service_gap(_) do
    animal_id = Available.animal_id
    ServiceGapX.insert(
      ServiceGapX.attrs(@iso_date, @iso_bumped_date, "reason", animal_id: animal_id)
    )
    
    [complete_animal: AnimalApi.showable!(animal_id, @institution)]
  end

  defp original_gap(%Animal{service_gaps: [original | _]}), do: original
end
