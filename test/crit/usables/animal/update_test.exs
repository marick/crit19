defmodule Crit.Usables.Animal.UpdateTest do
  use Crit.DataCase
  alias Crit.Usables.Animal
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars.Available

  @tag :skip
  test "updating the name" do
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
  end

  @tag :skip
  test "unique name constraint violation produces changeset" do
    {string_id, shown_animal} = showable_animal_named("Original Bossie")
    showable_animal_named("already exists")
    params = %{"name" => "already exists"}

    assert {:error, changeset} =
      AnimalApi.update(string_id, params, @institution)

    assert shown_animal == changeset.data

    assert "has already been taken" in errors_on(changeset).name
  end

  @tag :skip
  test "optimistic concurrency failure produces new animal" do
    {string_id, original} = showable_animal_named("Original Bossie")

    update = fn name -> 
      params = %{"name" => name,
                 "lock_version" => to_string(original.lock_version)
                }
      AnimalApi.update(string_id, params, @institution)
    end

    assert {:ok, _} = update.("this version wins")
    assert {:error, changeset} = update.("this version loses")

    # IO.inspect changeset.data

    assert [{:optimistic_lock_error, _template_invents_msg}] = changeset.errors
    # Update form with new version.
    assert changeset.data.name == "this version wins"
    # All changes have been wiped out.
    assert changeset.changes == %{}
  end

  test "optimistic lock failure wins" do
    # That means that, if both kinds of errors could happen, the
    # user will get a data refresh with message about the lock
    # failure.  The user will likely have to reenter data but that's
    # OK because such clashes will be incredibly rare. (They
    # wouldn't be worth checking for, except that I want to learn
    # how to handle optimistic locking.
    {string_id, original} = showable_animal_named("Original Bossie")

    update = fn name -> 
      params = %{"name" => name,
                 "lock_version" => to_string(original.lock_version)
                }
      AnimalApi.update(string_id, params, @institution)
    end

    assert {:ok, _} = update.("this version wins")
    assert {:error, changeset} = update.("this version wins")

    # Just the one error
    assert [{:optimistic_lock_error, _template_invents_msg}] = changeset.errors

  end

  defp showable_animal_named(name) do
    id = Available.animal_id(name: name)
    {to_string(id), 
     AnimalApi.showable!(id, @institution)
    }
  end
end
