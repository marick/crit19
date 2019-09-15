defmodule Crit.Usables.Internal.AnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Animal
  alias Crit.Usables.Animal.TxPart
  # import Ecto.Changeset
  alias Crit.Sql

  describe "creational changesets - support" do
    test "errors (none should be possible without client-side hackery)" do
      {:error, changeset} = Animal.creational_changesets(%{"names" => " fod"})
      
      refute changeset.valid?
      assert "can't be blank" in errors_on(changeset).species_id
    end

    test "N changesets for N names" do
      params = %{
        "species_id" => "0",
        "names" => "a, b, c"
      }
      {:ok, [a, b, c]} = Animal.creational_changesets(params)
      
      assert a.valid?
      assert b.valid?
      assert c.valid?

      assert a.changes.name == "a"
      assert b.changes.name == "b"
      assert c.changes.name == "c"
    end
  end


  describe "contributions to a transaction" do
    test "producing multiple animals" do 
      species_id = 1
      
      params = %{
        "species_id" => species_id,
        "names" => "Bossie, Jake"
      }

      {:ok, changesets} = Animal.creational_changesets(params)

      [bossie, jake] =
        changesets
        |> TxPart.creation(@default_short_name)
        |> Sql.transaction(@default_short_name)
        |> result_animal_ids
        |> Enum.map(&inserted_animal/1)

      assert bossie.name == "Bossie"
      assert bossie.species_id == species_id
      
      assert jake.name == "Jake"
      assert jake.species_id == species_id
    end
  end

  def result_animal_ids({:ok, %{animal_ids: animal_ids}}), do: animal_ids

  def inserted_animal(animal_id),
    do: Sql.get(Animal, animal_id, @default_short_name)
  
end
