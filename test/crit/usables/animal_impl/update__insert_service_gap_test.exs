defmodule Crit.Usables.AnimalImpl.UpdateInsertServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal
  alias Crit.Sql

  alias Crit.X.AnimalX
  import Crit.Usables.Schemas.ServiceGap, only: [span: 2]

  import Crit.Assertions.Changeset

  # Let's set the context: an animal with one service gap. It will be edited in
  # various ways. 
  defp an_updatable_animal_with_one_service_gap(_) do
    %{id: animal_id} = Factory.sql_insert!(:animal, @institution)
    Factory.sql_insert!(:service_gap, [animal_id: animal_id], @institution)
    
    [animal: AnimalApi.updatable!(animal_id, @institution)]
  end
  
  describe "adding a service gap" do
    setup :an_updatable_animal_with_one_service_gap

    @addition_input %{
      in_service_date: @later_iso_date,
      out_of_service_date: @later_iso_bumped_date,
      reason: "addition",
      delete: false
    }

    # These are the *non-virtual* fields that must be present in the CHANGESET
    @addition_changeset %{
      reason: "addition", 
      span: span(@later_date, @later_bumped_date)
   }

    # These are the fields returned from a successful SQL.update. 
    # The `span` field is also returned. However, because it's a compound
    # structure, it is unlikely to be used for, say, filling in a form.
    # In any case, notice that it *can't* be used as part of the input used
    # in a further update.
    @addition_update_result %{
      id: &is_integer/1,
      in_service_date: @later_date,
      out_of_service_date: @later_bumped_date,
      reason: "addition",
      delete: false,

      span: span(@later_date, @later_bumped_date)
    }

    # This is an "updatable" version of an animal. That is, it
    # contains all the values needed for a later update
    # (`in_service_date` and `out_of_service_date`). It also contains
    # the actual database values for further use (`id` and `span`).
    @addition_retrieval_result @addition_update_result
    
    setup(%{animal: animal}) do
      [animal_attrs: AnimalX.attrs_plus_service_gap(animal, @addition_input)]
    end
    
    test "service gap CHANGESETS produced by `Animal.update_changeset`",
      %{animal: animal, animal_attrs: attrs} do

      [_, new_changeset] = make_changesets(animal, attrs)

      # The new service gap, however, has a fleshed-out changeset
      new_changeset
      |> assert_valid
      |> assert_changes(@addition_changeset)
      # Just to confirm that this changeset will produce an insertion
      |> assert_field(action: :insert)
    end

    test "the results of the UPDATE, which can be used for a further update",
      %{animal: animal, animal_attrs: attrs} do

      [_, added_gap] = perform_update(animal, attrs)

      assert_fields(added_gap, @addition_update_result)
    end

    test "confirming the update represents the PERSISTED VALUE",
      # We emphasize (by omitting others) those fields necessary for an update
      %{animal: animal, animal_attrs: attrs} do

      perform_update(animal, attrs)
      [_, added_gap] = retrieve_update(animal)

      assert_fields(added_gap, @addition_retrieval_result)
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

  defp make_changesets(animal, attrs),
    do: Animal.update_changeset(animal, attrs).changes.service_gaps

  defp perform_update(animal, attrs) do 
    {:ok, %Animal{service_gaps: gaps}} = 
      animal
      |> Animal.update_changeset(attrs)
      |> Sql.update(@institution)
    gaps
  end

  defp retrieve_update(animal) do 
    %Animal{service_gaps: gaps} = AnimalApi.updatable!(animal.id, @institution)
    gaps
  end
end
