defmodule Crit.UsablesTest do
  use Crit.DataCase

  alias Crit.Usables

  describe "animals" do
    alias Crit.Usables.Animal

    @valid_attrs %{lock_version: 42, name: "some name", species: "some species"}
    @update_attrs %{lock_version: 43, name: "some updated name", species: "some updated species"}
    @invalid_attrs %{lock_version: nil, name: nil, species: nil}

    def animal_fixture(attrs \\ %{}) do
      {:ok, animal} =
        attrs
        |> Enum.into(@valid_attrs)
        |> Usables.create_animal()

      animal
    end

    test "list_animals/0 returns all animals" do
      animal = animal_fixture()
      assert Usables.list_animals() == [animal]
    end

    test "get_animal!/1 returns the animal with given id" do
      animal = animal_fixture()
      assert Usables.get_animal!(animal.id) == animal
    end

    test "create_animal/1 with valid data creates a animal" do
      assert {:ok, %Animal{} = animal} = Usables.create_animal(@valid_attrs)
      assert animal.lock_version == 42
      assert animal.name == "some name"
      assert animal.species == "some species"
    end

    test "create_animal/1 with invalid data returns error changeset" do
      assert {:error, %Ecto.Changeset{}} = Usables.create_animal(@invalid_attrs)
    end

    test "update_animal/2 with valid data updates the animal" do
      animal = animal_fixture()
      assert {:ok, %Animal{} = animal} = Usables.update_animal(animal, @update_attrs)
      assert animal.lock_version == 43
      assert animal.name == "some updated name"
      assert animal.species == "some updated species"
    end

    test "update_animal/2 with invalid data returns error changeset" do
      animal = animal_fixture()
      assert {:error, %Ecto.Changeset{}} = Usables.update_animal(animal, @invalid_attrs)
      assert animal == Usables.get_animal!(animal.id)
    end

    test "delete_animal/1 deletes the animal" do
      animal = animal_fixture()
      assert {:ok, %Animal{}} = Usables.delete_animal(animal)
      assert_raise Ecto.NoResultsError, fn -> Usables.get_animal!(animal.id) end
    end

    test "change_animal/1 returns a animal changeset" do
      animal = animal_fixture()
      assert %Ecto.Changeset{} = Usables.change_animal(animal)
    end
  end
end
