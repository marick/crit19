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

  # Let's set the context: an animal with one service gap. It will be edited in
  # various ways. 
  defp an_updatable_animal_with_one_service_gap(_) do
    animal_id = Available.animal_id
    ServiceGapX.insert(
      ServiceGapX.attrs(@iso_date, @iso_bumped_date, "reason", animal_id: animal_id)
    )
    
    [animal: AnimalApi.showable!(animal_id, @institution)]
  end
  
  describe "adding a service gap" do
    setup :an_updatable_animal_with_one_service_gap

    setup(%{animal: animal}) do
      new_gap = %{in_service_date: @later_iso_date,
                  out_of_service_date: @later_iso_bumped_date,
                  reason: "addition"
                 }
      [animal_attrs: AnimalX.attrs_plus_service_gap(animal, new_gap)]
    end
    
    test "service gap CHANGESETS produced by `Animal.update_changeset`",
      %{animal: animal, animal_attrs: attrs} do

      [_, new_changeset] = make_changesets(animal, attrs)

      # The new service gap, however, has a fleshed-out changeset
      new_changeset
      |> assert_valid
      |> assert_changes(reason: "addition",
                        span: span(@later_date, @later_bumped_date))
    end

    test "the results of the UPDATE, which can be used for a further update",
      %{animal: animal, animal_attrs: attrs} do

      [_, added_gap] = perform_update(animal, attrs)

      added_gap
      |> assert_fields(in_service_date: @later_date,
                       out_of_service_date: @later_bumped_date,
                       reason: "addition",
                       span: span(@later_date, @later_bumped_date),
                       id: &is_integer/1)
    end

    test "P.S. adding a service gap doesn't change the existing one", 
      %{animal: animal, animal_attrs: attrs} do

      [retained_changeset, _] = make_changesets(animal, attrs)
      # No changes for the old service gap (therefore, it will not be UPDATEd)
      retained_changeset |> assert_valid |> assert_unchanged

      # See?
      [retained_gap, _] = perform_update(animal, attrs)
      assert retained_gap == original_gap(animal)
    end
  end

  defp original_gap(animal), do: AnimalX.service_gap_n(animal, 0)
  defp new_gap(animal), do: AnimalX.service_gap_n(animal, 1)

  defp make_changesets(animal, attrs),
    do: Animal.update_changeset(animal, attrs).changes.service_gaps

  defp perform_update(animal, attrs) do 
    {:ok, %Animal{service_gaps: gaps}} = 
      animal
      |> Animal.update_changeset(attrs)
      |> Sql.update(@institution)
    gaps
  end
  
  
end
