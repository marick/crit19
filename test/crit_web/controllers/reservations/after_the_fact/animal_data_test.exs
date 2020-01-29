defmodule CritWeb.Reservations.AfterTheFact.AnimalDataTest do
  use Crit.DataCase, async: true
  alias CritWeb.Reservations.AfterTheFact.AnimalData

  describe "form synthesizes some values" do
    test "success" do
      params = %{"chosen_animal_ids" => %{"1" => "true"},
                 "transaction_key" => "uuid"}

      changeset = AnimalData.changeset(params)
      
      assert_lists_equal [1], changeset.changes.chosen_animal_ids
      assert "uuid" == changeset.changes.transaction_key
    end
  end
end
