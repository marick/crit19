defmodule Crit.Usables.Internal.AnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Animal

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
end
