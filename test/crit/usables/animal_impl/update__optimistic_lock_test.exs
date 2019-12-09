defmodule Crit.Usables.AnimalImpl.UpdateOptimisticLockTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi

  alias Crit.Extras.AnimalT

  describe "optimistic concurrency" do
    setup do
      original = AnimalT.updatable_animal_named("Original Bossie")

      update = fn animal, name ->
        params = AnimalT.params_except(original, %{
            "name" => name,
            "lock_version" => to_string(animal.lock_version)})
        AnimalApi.update(original.id, params, @institution)
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

      AnimalT.updatable_animal_named("preexisting")

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
end
