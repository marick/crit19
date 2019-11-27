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
    
    test "service gap changesets produced by `Animal.update_changeset`",
      %{complete_animal: complete_animal, animal_attrs: attrs} do

      [old_sg_changeset, new_sg_changeset] = 
        Animal.update_changeset(complete_animal, attrs).changes.service_gaps

      # No changes for the old service gap (therefore, it will not be UPDATEd)
      old_sg_changeset |> assert_valid |> assert_unchanged

      # The new service gap, however, has a fleshed-out changeset
      new_sg_changeset
      |> assert_valid
      |> assert_changes(reason: "addition",
                        span: span(@later_date, @later_bumped_date))
    end

    test "the results of using the changeset",
      %{complete_animal: complete_animal, animal_attrs: attrs} do

      {:ok, %{service_gaps: [retained_gap, added_gap]}} = 
        complete_animal
        |> Animal.update_changeset(attrs)
        |> Sql.update(@institution)
      
      assert retained_gap == original_gap(complete_animal)

      added_gap
      |> assert_fields(in_service_date: @later_date,
                       out_of_service_date: @later_bumped_date,
                       reason: "addition",
                       span: span(@later_date, @later_bumped_date),
                       id: &is_integer/1)
    end
  end

  defp an_existing_animal_with_one_service_gap(_) do
    animal_id = Available.animal_id
    ServiceGapX.insert(
      ServiceGapX.attrs(@iso_date, @iso_bumped_date, "reason", animal_id: animal_id)
    )
    
    [complete_animal: AnimalApi.showable!(animal_id, @institution)]
  end

  defp original_gap(animal), do: AnimalX.service_gap_n(animal, 0)
  defp new_gap(animal), do: AnimalX.service_gap_n(animal, 1)
end
