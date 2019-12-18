defmodule Crit.Usables.AnimalImpl.UpdateJustAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Extras.AnimalT
  alias Ecto.Datespan
  alias Crit.Exemplars

  # Tests that do NOT involve service gaps

  describe "updating the name and common behaviors" do
    test "success" do
      original = AnimalT.updatable_animal_named("Original Bossie")
      params = AnimalT.params_except(original, %{"name" => "New Bossie"})

      AnimalT.update_for_success(original.id, params)
      |> assert_fields(name: "New Bossie", lock_version: 2)
      |> assert_copy(original,
                     except: [:name, :lock_version, :updated_at])
      |> assert_copy(AnimalApi.updatable!(original.id, @institution),
                     except: [:updated_at])
    end

    test "unique name constraint violation produces changeset" do
      original = AnimalT.updatable_animal_named("Original Bossie")
      AnimalT.updatable_animal_named("already exists")
      params = AnimalT.params_except(original, %{"name" => "already exists"})

      AnimalT.update_for_error_changeset(original.id, params)
      |> assert_error(name: "has already been taken")
    end
  end

  describe "updating the service span" do
    setup do
      [dates: Exemplars.Date.service_dates()]
    end
    
    test "update in-service date", %{dates: dates} do

      original_animal = AnimalT.dated_animal(dates.iso_in_service, "never")
        
      params = %{"in_service_datestring" => dates.iso_next_in_service,
                 "out_of_service_datestring" => "never"}
      AnimalT.update_for_success(original_animal.id, params)
      |> assert_fields(
             in_service_datestring: dates.iso_next_in_service,
             span: Datespan.infinite_up(dates.next_in_service, :inclusive),
             lock_version: 2)
      |> assert_copy(original_animal,
           except: [:in_service_datestring, :span, :lock_version, :in_service_date])
    end
  end
end
