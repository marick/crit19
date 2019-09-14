defmodule Crit.Usables.Internal.AnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Animal
  #alias Crit.Usables.Animal.TxPart
  # import Ecto.Changeset
  # alias Crit.Sql

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
    @tag :skip
    test "this is wrong...." do 
      # names = ["Bossie", "Fred"]
      # species_id = 1
      
      # params = %{
      #   "species_id" => species_id
      # }

      # inserted =
      #   params
      #   |> Animal.initial_changeset
      #   |> TxPart.creation(@default_short_name)
      #   |> Sql.transaction(@default_short_name)
    end
  end
end
