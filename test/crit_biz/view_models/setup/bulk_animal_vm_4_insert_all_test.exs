defmodule CritBiz.ViewModels.Setup.BulkAnimalVM.InsertAllTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  # alias Crit.Exemplars, as: Ex
  # alias Ecto.Changeset
  alias Crit.Setup.AnimalApi2, as: AnimalApi

  @daisy_to_insert Factory.build(:animal_new, name: "Daisy")

  setup do
    {:ok, [daisy_vm]} = 
      VM.BulkAnimalNew.insert_all([@daisy_to_insert], @institution)
    
    [daisy_vm: daisy_vm]
  end
  
  describe "success" do
    test "what the on-disk version looks like", %{daisy_vm: daisy_vm} do
      AnimalApi.one_by_id(daisy_vm.id, @institution)
      |> assert_shape(%Schemas.Animal{})
      |> assert_schema_copy(@daisy_to_insert, ignoring: [:id])
    end

    test "what the returned view models look like", %{daisy_vm: daisy_vm} do
      expected = VM.Animal.fetch(:one_for_summary, daisy_vm.id, @institution) 
      
      daisy_vm
      |> assert_shape(%VM.Animal{})
      |> assert_copy(expected)
    end
  end

  @tag :skip
  test "animals are returned sorted in alphabetical order" do
    # daisy_to_insert = Factory.build(:animal_new, name: "Daisy")
    # jake_in = Factory.build(:animal_new, name: "Jake")
    # {:ok, [daisy, jake]} = 
    #   VM.BulkAnimalNew.insert_all([daisy_to_insert, jake_in], @institution)
  end

  @tag :skip
  test "trying to rename an animal to an existing animal" 

end
