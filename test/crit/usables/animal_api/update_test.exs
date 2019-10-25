defmodule Crit.Usables.AnimalApi.UpdateTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.Animal
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars.Available

  describe "updating the name and common behaviors" do
    test "success" do
      {string_id, original} = showable_animal_named("Original Bossie")
      params = %{"name" => "New Bossie",
                 "species_id" => "this should be ignored",
                 "id" => "this should also be ignored"
                }

      assert {:ok, new_animal} =
        AnimalApi.update(string_id, params, @institution)

      assert new_animal == %Animal{original |
                                   name: "New Bossie",
                                   lock_version: 2
                                  }

      assert new_animal == AnimalApi.showable!(original.id, @institution)
    end

    test "unique name constraint violation produces changeset" do
      {string_id, _} = showable_animal_named("Original Bossie")
      showable_animal_named("already exists")
      params = %{"name" => "already exists"}

      assert {:error, changeset} = AnimalApi.update(string_id, params, @institution)
      assert "has already been taken" in errors_on(changeset).name
    end


  end


  describe "updating gaps" do
    @tag :skip
    test "update in-service date" do
      original = "2011-11-11"
      new = "2222-01-22"
      id = Available.animal_id(in_service_date: original)
      
      params = %{"in_service_date" => new}

      assert {:ok, new_animal} =
        AnimalApi.update(to_string(id), params, @institution)

      assert new_animal.in_service_date == new
    end

    @tag :skip
    test "update out-of-service date"

    @tag :skip
    test "delete out-of-service date" # and make sure join table is updated

    @tag :skip
    test "add new out-of-service date" # and make sure join table is updated

    @tag :skip
    test "allow date updates to work even though name update fails."
  end


  describe "optimistic concurrency" do
    setup do
      {string_id, original} = showable_animal_named("Original Bossie")

      update = fn animal, name ->
        params = %{"name" => name,
                   "lock_version" => to_string(animal.lock_version)
                  }
        AnimalApi.update(string_id, params, @institution)
      end
      [original: original, update: update]
    end

    test "optimistic concurrency failure produces changeset with new animal",
      %{original: original, update: update} do

      assert {:ok, updated_first} = update.(original, "this version wins")
      assert {:error, changeset} = update.(original, "this version loses")

      assert [{:optimistic_lock_error, _template_invents_msg}] = changeset.errors
      # All changes have been wiped out.
      assert changeset.changes == %{}

      # It is the updated version that is to fill in fields.
      assert changeset.data == updated_first
      # Most interestingly...
      assert changeset.data.name == updated_first.name
      assert changeset.data.lock_version == updated_first.lock_version
    end

    test "successful name change updates lock_version in displayed value",
      %{original: original, update: update} do

      assert {:ok, updated} = update.(original, "this is a new name")
      assert updated.lock_version == 2
    end

    test "Unsuccessful name change DOES NOT update lock_version",
      %{original: original, update: update} do

      showable_animal_named("preexisting")

      assert {:error, changeset} = update.(original, "preexisting")

      assert original.lock_version == 1
      assert changeset.data.lock_version == original.lock_version
      assert changeset.changes[:lock_version] == nil
    end

    test "optimistic lock failure wins", %{original: original, update: update} do
      # Bump the lock version
      {:ok, _} = update.(original, "this version wins")

      assert {:error, changeset} = update.(original, "this version wins")

      # Just the one error
      assert [{:optimistic_lock_error, _template_invents_msg}] = changeset.errors
    end
  end

  defp showable_animal_named(name) do
    id = Available.animal_id(name: name)
    {to_string(id),
     AnimalApi.showable!(id, @institution)
    }
  end
end
