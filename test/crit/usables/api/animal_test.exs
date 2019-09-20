defmodule Crit.Usables.Api.AnimalTest do
  use Crit.DataCase
  alias Crit.Usables

  @iso_date "2001-09-05"
  #  @date Date.from_iso8601!(@iso_date)

  # @later_iso_date "2011-09-05"
  # @later_date Date.from_iso8601!(@later_iso_date)

  @species_id 1

  describe "basics of animal creation and retrieval" do

    setup do
      params = %{
        "species_id" => @species_id,
        "names" => "Bossie, Jake",
        "start_date" => @iso_date,
        "end_date" => "never"
      }
      [result: Usables.create_animal(params, @default_short_name)]
    end  

    test "non-association fields are returned", %{result: result} do 
      assert {:ok, [bossie, jake]} = result

      assert bossie.name == "Bossie"
      refute Ecto.assoc_loaded?(bossie.service_gaps)

      assert jake.name == "Jake"
      refute Ecto.assoc_loaded?(jake.service_gaps)
    end

    @tag :skip
    test "virtual fields are stripped" do
      # like returning N records, each with an N-entry `names` field
    end

    @tag :skip
    test "Handle the species associated field" do
      # In the above, the following will not work
      # assert bossie.species.id == @species_id
      # assert jake.species.id == @species_id
    end
  end

  describe "fetching an animal" do
    setup do
      params = %{
        "species_id" => @species_id,
        "names" => "Bossie, Jake",
        "start_date" => @iso_date,
        "end_date" => "never"
      }
      [result: Usables.create_animal(params, @default_short_name)]
    end  
    
    
    test "fetching by name" do
      assert animal = Usables.get_complete_animal_by_name("Bossie", @default_short_name)
      assert animal.name == "Bossie"
      assert Ecto.assoc_loaded?(animal.service_gaps)
    end

    test "errors return nil" do
      assert nil == Usables.get_complete_animal_by_name("lossie", @default_short_name)
    end

    test "fetch by id" do
      id = Usables.get_complete_animal_by_name("Bossie", @default_short_name).id
      animal = Usables.get_complete_animal!(id, @default_short_name)
                        
      assert animal.name == "Bossie"
      assert Ecto.assoc_loaded?(animal.service_gaps)
    end
    
    test "no such id" do
      assert_raise KeyError, fn -> 
        Usables.get_complete_animal!(83483, @default_short_name)
      end
    end
  end



  # describe "animals" do
  #   alias Crit.Usables.Animal

  #   @valid_attrs %{lock_version: 42, name: "some name", species: "some species"}
  #   @update_attrs %{lock_version: 43, name: "some updated name", species: "some updated species"}
  #   @invalid_attrs %{lock_version: nil, name: nil, species: nil}

  #   def animal_fixture(attrs \\ %{}) do
  #     {:ok, animal} =
  #       attrs
  #       |> Enum.into(@valid_attrs)
  #       |> Usables.create_animal()

  #     animal
  #   end

  #   test "list_animals/0 returns all animals" do
  #     animal = animal_fixture()
  #     assert Usables.list_animals() == [animal]
  #   end

  #   test "get_animal!/1 returns the animal with given id" do
  #     animal = animal_fixture()
  #     assert Usables.get_animal!(animal.id) == animal
  #   end

  #   test "create_animal/1 with valid data creates a animal" do
  #     assert {:ok, %Animal{} = animal} = Usables.create_animal(@valid_attrs)
  #     assert animal.lock_version == 42
  #     assert animal.name == "some name"
  #     assert animal.species == "some species"
  #   end

  #   test "create_animal/1 with invalid data returns error changeset" do
  #     assert {:error, %Ecto.Changeset{}} = Usables.create_animal(@invalid_attrs)
  #   end

  #   test "update_animal/2 with valid data updates the animal" do
  #     animal = animal_fixture()
  #     assert {:ok, %Animal{} = animal} = Usables.update_animal(animal, @update_attrs)
  #     assert animal.lock_version == 43
  #     assert animal.name == "some updated name"
  #     assert animal.species == "some updated species"
  #   end

  #   test "update_animal/2 with invalid data returns error changeset" do
  #     animal = animal_fixture()
  #     assert {:error, %Ecto.Changeset{}} = Usables.update_animal(animal, @invalid_attrs)
  #     assert animal == Usables.get_animal!(animal.id)
  #   end

  #   test "delete_animal/1 deletes the animal" do
  #     animal = animal_fixture()
  #     assert {:ok, %Animal{}} = Usables.delete_animal(animal)
  #     assert_raise Ecto.NoResultsError, fn -> Usables.get_animal!(animal.id) end
  #   end

  #   test "change_animal/1 returns a animal changeset" do
  #     animal = animal_fixture()
  #     assert %Ecto.Changeset{} = Usables.change_animal(animal)
  #   end
  # end
end
