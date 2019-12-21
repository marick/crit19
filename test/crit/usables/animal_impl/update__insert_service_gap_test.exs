defmodule Crit.Usables.AnimalImpl.UpdateInsertServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal

  alias Crit.Extras.{AnimalT,ServiceGapT}

  import Crit.Assertions.Changeset
  import Crit.Setups
  alias Ecto.Datespan

  setup :an_updatable_animal_with_one_service_gap
  
  describe "adding a service gap" do

    @addition_input %{
      in_service_datestring: @later_iso_date,
      out_of_service_datestring: @later_iso_bumped_date,
      reason: "addition",
      delete: false
    }

    # These are the *non-virtual* fields that must be present in the CHANGESET
    @addition_changeset %{
      reason: "addition", 
      span: Datespan.customary(@later_date, @later_bumped_date)
   }

    # These are the fields returned from a successful SQL.update. 
    # The `span` field is also returned. However, because it's a compound
    # structure, it is unlikely to be used for, say, filling in a form.
    # In any case, notice that it *can't* be used as part of the input used
    # in a further update.
    @addition_update_result %{
      id: &is_integer/1,
      in_service_datestring: @later_iso_date,
      out_of_service_datestring: @later_iso_bumped_date,
      reason: "addition",
      delete: false,

      span: Datespan.customary(@later_date, @later_bumped_date)
    }

    # This is an "updatable" version of an animal. That is, it
    # contains all the values needed for a later update
    # (`in_service_datestring` and `out_of_service_datestring`). It also contains
    # the actual database values for further use (`id` and `span`).
    @addition_retrieval_result @addition_update_result
    
    setup(%{animal: animal}) do
      [animal_attrs: AnimalT.attrs_plus_service_gap(animal, @addition_input)]
    end
    
    test "service gap CHANGESETS produced by `Animal.update_changeset`",
      %{animal: animal, animal_attrs: attrs} do

      [_, new_changeset] = ServiceGapT.make_changesets(animal, attrs)

      # The new service gap, however, has a fleshed-out changeset
      new_changeset
      |> assert_valid
      |> assert_changes(@addition_changeset)
      # Just to confirm that this changeset will produce an insertion
      |> assert_field(action: :insert)
    end

    test "the results of the UPDATE, which can be used for a further update",
      %{animal: animal, animal_attrs: attrs} do

      [_, added_gap] = ServiceGapT.update_animal_for_service_gaps(animal, attrs)

      assert_fields(added_gap, @addition_update_result)
    end

    test "confirming the update represents the PERSISTED VALUE",
      # We emphasize (by omitting others) those fields necessary for an update
      %{animal: animal, animal_attrs: attrs} do

      ServiceGapT.update_animal_for_service_gaps(animal, attrs)
      
      [_, added_gap] = retrieve_update(animal)

      assert_fields(added_gap, @addition_retrieval_result)
    end

    test "P.S. adding a service gap doesn't change the existing one", 
      %{animal: animal, animal_attrs: attrs} do

      [retained_changeset, _] = ServiceGapT.make_changesets(animal, attrs)
      # No changes for the old service gap (therefore, it will not be UPDATEd)
      assert_valid(retained_changeset)
      assert retained_changeset.changes == %{institution: @institution}

      # See?
      [retained_gap, _] = ServiceGapT.update_animal_for_service_gaps(animal, attrs)
      assert_copy(retained_gap, original_gap(animal), ignoring: [:institution])
    end
  end


  defp original_gap(animal), do: AnimalT.service_gap_n(animal, 0)

  defp retrieve_update(animal) do 
    %Animal{service_gaps: gaps} = AnimalApi.updatable!(animal.id, @institution)
    gaps
  end
end
