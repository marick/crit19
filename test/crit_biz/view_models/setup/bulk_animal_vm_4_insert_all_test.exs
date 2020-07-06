defmodule CritBiz.ViewModels.Setup.BulkAnimalVM.InsertAllTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  # alias Crit.Exemplars, as: Ex
  # alias Ecto.Changeset
  alias Crit.Setup.AnimalApi2, as: AnimalApi


  test "success" do
    daisy_in = Factory.build(:animal_new, name: "Daisy")
    {:ok, [daisy_vm]} = 
      VM.BulkAnimalNew.insert_all([daisy_in], @institution)

    AnimalApi.one_by_id(daisy_vm.id, @institution)
    |> assert_shape(%Schemas.Animal{})
    |> assert_schema_copy(daisy_in, ignoring: [:id])
    |> assert_field(id: &is_integer/1)
  end

  @tag :skip
  test "animals are returned sorted in alphabetical order" do
    # daisy_in = Factory.build(:animal_new, name: "Daisy")
    # jake_in = Factory.build(:animal_new, name: "Jake")
    # {:ok, [daisy, jake]} = 
    #   VM.BulkAnimalNew.insert_all([daisy_in, jake_in], @institution)
  end

  @tag :skip
  test "trying to rename an animal to an existing animal" 

end
