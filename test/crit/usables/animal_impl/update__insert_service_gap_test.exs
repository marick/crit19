defmodule Crit.Usables.AnimalImpl.UpdateInsertServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal

  alias Crit.Extras.{AnimalT,ServiceGapT}

  import Crit.Setups
  alias Ecto.Datespan
  alias Ecto.Changeset

  setup :an_updatable_animal_with_one_service_gap
  
  describe "adding a service gap" do
    setup(%{animal: animal}) do
      params =
        AnimalT.unchanged_params(animal)
        |> put_in(["service_gaps", "0"],
             %{"in_service_datestring" => @later_iso_date,
               "out_of_service_datestring" => @later_iso_bumped_date,
               "reason" => "addition",
               "delete" => false,
               "institution" => @institution})
      
      [params: params]
    end

    test "the results of the UPDATE, which can be used for a further update",
      %{animal: animal, params: params} do

      [added_gap, _] = AnimalT.update_for_success(animal.id, params).service_gaps

      # These are the fields returned from a successful SQL.update. 
      # The `span` field is also returned. However, because it's a compound
      # structure, it is unlikely to be used for, say, filling in a form.
      # In any case, notice that it *can't* be used as part of the input used
      # in a further update.

      assert_fields(added_gap,
        id: &is_integer/1,
        in_service_datestring: @later_iso_date,
        out_of_service_datestring: @later_iso_bumped_date,
        reason: "addition",
        delete: false,
        
        span: Datespan.customary(@later_date, @later_bumped_date)
        )
    end

    test "confirming the update represents the PERSISTED VALUE",
      # We emphasize (by omitting others) those fields necessary for an update
      %{animal: animal, params: params} do

      ServiceGapT.update_animal_for_service_gaps(animal, params)

      # Note: currently, service gaps are returned in order of id.
      # This is not right.
      [_, added_gap] = retrieve_update(animal)

      # This is an "updatable" version of an animal. That is, it
      # contains all the values needed for a later update
      # (`in_service_datestring` and `out_of_service_datestring`). It also contains
      # the actual database values for further use (`id` and `span`).
      assert_fields(added_gap,
        id: &is_integer/1,
        in_service_datestring: @later_iso_date,
        out_of_service_datestring: @later_iso_bumped_date,
        reason: "addition",
        delete: false,
        
        span: Datespan.customary(@later_date, @later_bumped_date)
        )
    end

    test "P.S. adding a service gap doesn't change the existing one", 
      %{animal: animal, params: params} do

      [original_retained] = animal.service_gaps


      [_, returned_retained] =
        ServiceGapT.update_animal_for_service_gaps(animal, params)
      assert returned_retained == original_retained

      [fetched_retained, _] = retrieve_update(animal)
      assert fetched_retained == original_retained
    end

    test "the insertion fails", %{animal: animal, params: initial_params} do
      params =
        initial_params
        |> put_in(["service_gaps", "0"],
             %{"in_service_datestring" => @iso_date_2,
               "out_of_service_datestring" => @iso_date_1,
               "reason" => "",
               "delete" => false,
               "institution" => @institution})

      animal_changeset = AnimalT.update_for_error_changeset(animal.id, params)
      assert [in_error, unchanged] = Changeset.get_change(animal_changeset, :service_gaps)

      in_error
      |> assert_errors(out_of_service_datestring: @date_misorder_message,
                       reason: @blank_message)
      |> assert_changes(in_service_datestring: @iso_date_2,
                        out_of_service_datestring: @iso_date_1)
      |> assert_unchanged([:reason, :delete])

      unchanged
      |> assert_valid
      |> assert_no_changes
    end
  end

  defp retrieve_update(animal) do 
    %Animal{service_gaps: gaps} = AnimalApi.updatable!(animal.id, @institution)
    gaps
  end
end
