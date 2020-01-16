defmodule Crit.Usables.AnimalImpl.UpdateDeleteServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Extras.AnimalT
  import Crit.Setups

  setup :an_updatable_animal_with_one_service_gap

  setup %{animal: animal} do
    params =
      AnimalT.unchanged_params(animal)
      |> put_in(["service_gaps", "1", "delete"], "true")
    
    [animal: animal, params: params]
  end
  
  describe "deleting a service gap" do

    test "the results of the UPDATE",
      %{animal: animal, params: params} do

      AnimalT.update_for_success(animal.id, params)
      |> assert_field(service_gaps: [])
    end

    test "confirming the update represents the PERSISTED VALUE",
      %{animal: animal, params: params} do

      AnimalT.update_for_success(animal.id, params)

      AnimalApi.updatable!(animal.id, @institution)
      |> assert_field(service_gaps: [])
    end
  end
end
