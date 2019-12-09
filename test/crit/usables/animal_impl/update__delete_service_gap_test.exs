defmodule Crit.Usables.AnimalImpl.UpdateDeleteServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.Animal
  alias Crit.Sql
  alias Crit.Extras.AnimalT
  import Crit.Assertions.Changeset
  import Crit.Setups

  setup :an_updatable_animal_with_one_service_gap

  setup %{animal: animal} do
    
    attrs =
      AnimalT.attrs(animal)
      |> put_in([:service_gaps, Access.at(0), :delete], true) 
    
    [animal_attrs: attrs]
  end
  
  describe "deleting a service gap" do
    test "service gap CHANGESETS produced by `Animal.update_changeset`",
      %{animal: animal, animal_attrs: attrs} do

      [sg_changeset] = make_changesets(animal, attrs)

      sg_changeset
      |> assert_valid
      |> assert_field(action: :delete)
    end

    test "the results of the UPDATE",
      %{animal: animal, animal_attrs: attrs} do

      assert [] == perform_update(animal, attrs)
    end

    test "confirming the update represents the PERSISTED VALUE",
      %{animal: animal, animal_attrs: attrs} do

      perform_update(animal, attrs)
      assert [] == AnimalApi.updatable!(animal.id, @institution).service_gaps
    end
  end



  defp make_changesets(animal, attrs) do
    Animal.update_changeset(animal, attrs).changes.service_gaps
  end

  defp perform_update(animal, attrs) do 
    {:ok, %Animal{service_gaps: gaps}} = 
      animal
      |> Animal.update_changeset(attrs)
      |> Sql.update(@institution)
    gaps
  end

end
