defmodule CritBiz.ViewModels.Setup.BulkAnimalVM.InsertAllTest do
  use Crit.DataCase, async: true
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas
  use FlowAssertions

  @daisy_to_insert Factory.build(:animal, name: "Daisy")

  setup do
    {:ok, [daisy_vm]} = 
      VM.BulkAnimal.insert_all([@daisy_to_insert], @institution)
    
    [daisy_vm: daisy_vm]
  end
  
  describe "success" do
    test "what the on-disk version looks like", %{daisy_vm: daisy_vm} do
      Schemas.Animal.Get.one_by_id(daisy_vm.id, @institution)
      |> assert_shape(%Schemas.Animal{})
      |> assert_same_schema(@daisy_to_insert, ignoring: [:id, :lock_version])

      # We don't check the lock version because we don't care what it's starting
      # value is, so long as it increments correctly. (It happens to be 2.)
    end

    test "what the returned view models look like", %{daisy_vm: daisy_vm} do
      expected = VM.Animal.fetch(:one_for_summary, daisy_vm.id, @institution) 
      
      daisy_vm
      |> assert_shape(%VM.Animal{})
      |> assert_same_map(expected)
    end
  end

  test "trying to rename an animal to an existing animal", %{daisy_vm: daisy_vm} do
    assert {:error, :constraint, %{message: message}} = 
      VM.BulkAnimal.insert_all([@daisy_to_insert], @institution)

    assert message =~ daisy_vm.name
  end
  
end
