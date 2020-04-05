defmodule Crit.Setup.AnimalImpl.UpdateOptimisticLockTest do
  use Crit.DataCase
  alias Crit.Setup.AnimalApi
  alias Crit.Extras.AnimalT

  describe "optimistic concurrency" do
    setup do
      old = AnimalT.updatable_animal_named("Original Bossie")
      [old: old]
    end

    test "failure produces changeset that restarts with new version of animal",
      %{old: old} do

      assert {:ok, new} = update_name(old, "this version wins")
      assert {:error, changeset} = update_name(old, "this version loses")

      changeset
      |> assert_no_changes # All changes have been wiped out.
      |> assert_data(name: "this version wins",
                     lock_version: old.lock_version + 1)
      # Template invents the error message
      |> assert_error(:optimistic_lock_error)
    end

    test "failure produces changeset that restarts with new version of animal NEW",
      %{old: old} do

      assert {:ok, new} = update_name(old, "this version wins")
      assert {:error, retry_changeset} = update_name(old, "this version loses")

      retry_changeset
      |> assert_no_changes         # wipes out user entries
      |> assert_data(name: "this version wins",
                     lock_version: old.lock_version + 1)

      # The error is noted, but the message is the template's responsibility
      |> assert_error(:optimistic_lock_error)
    end

    test "successful name change updates lock_version in displayed value",
      %{old: old} do

      assert {:ok, updated} = update_name(old, "this is a new name")
      assert updated.lock_version == old.lock_version + 1
    end

    test "Unsuccessful name change DOES NOT update lock_version",
      %{old: old} do

      AnimalT.updatable_animal_named("preexisting")

      assert {:error, changeset} = update_name(old, "preexisting")

      changeset
      |> assert_data(lock_version: old.lock_version)
      |> assert_unchanged(:lock_version)
    end

    test "optimistic lock failure takes precedence over other errors", %{old: old} do
      # Let's make a name unavailable
      AnimalT.updatable_animal_named("some other animal name")

      # Someone else edits an animal under edit
      assert {:ok, _} = update_name(old, "old animal, new name")

      # Two problems: lock error and name error
      assert {:error, changeset} = update_name(old, "some other animal name")

      # Just the one error
      assert [{:optimistic_lock_error, _template_invents_msg}] = changeset.errors
    end
  end

  defp update_name(animal, name) do 
    params = AnimalT.params_except(animal, %{"name" => name})
    AnimalApi.update(animal.id, params, @institution)
  end
end
