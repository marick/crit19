defmodule Crit.Usables.AnimalImpl.UpdateJustAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.X.AnimalX

  # Tests that do NOT involve service gaps

  describe "updating the name and common behaviors" do
    test "success" do
      original = AnimalX.updatable_animal_named("Original Bossie")
      params = AnimalX.params_except(original, %{"name" => "New Bossie"})

      AnimalX.update_for_success(original.id, params)
      |> assert_fields(name: "New Bossie", lock_version: 2)
      |> assert_copy(original,
                     except: [:name, :lock_version, :updated_at])
      |> assert_copy(AnimalApi.updatable!(original.id, @institution),
                     except: [:updated_at])
    end

    test "unique name constraint violation produces changeset" do
      original = AnimalX.updatable_animal_named("Original Bossie")
      AnimalX.updatable_animal_named("already exists")
      params = AnimalX.params_except(original, %{"name" => "already exists"})

      assert "has already been taken" in AnimalX.update_for_error(original.id, params).name
    end
  end
end
