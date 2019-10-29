defmodule Crit.Usables.AnimalApi.UpdateTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.Animal
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars.{Available, Date}
  alias Crit.Usables.FieldConverters.ToDate

  describe "updating the name and common behaviors" do
    test "success" do
      {string_id, original} = showable_animal_named("Original Bossie")
      params = params_except(original, %{"name" => "New Bossie"})

      assert {:ok, new_animal} =
        AnimalApi.update(string_id, params, @institution)

      assert new_animal == %Animal{original |
                                   name: "New Bossie",
                                   lock_version: 2
                                  }

      assert new_animal == AnimalApi.showable!(original.id, @institution)
    end

    test "unique name constraint violation produces changeset" do
      {string_id, original} = showable_animal_named("Original Bossie")
      showable_animal_named("already exists")
      params = params_except(original, %{"name" => "already exists"})

      assert {:error, changeset} = AnimalApi.update(string_id, params, @institution)
      assert "has already been taken" in errors_on(changeset).name
    end
  end


  describe "updating service dates" do
    setup do
      [dates: Date.service_dates()]
    end
    
    defp act id, params do
      assert {:ok, new_animal} =
        AnimalApi.update(to_string(id), params, @institution)
      new_animal
    end

    test "update in-service date", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: "never"
      )
        
      params = %{"in_service_datestring" => dates.iso_next_in_service,
                 "out_of_service_datestring" => "never",
                }
      new_animal = act(original_animal.id, params)
      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_next_in_service,
                             in_service_date: dates.next_in_service,
                             lock_version: 2
                           }
    end

    test "update out-of-service date", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        in_service_date: dates.in_service,
        out_of_service_datestring: dates.iso_out_of_service,
        out_of_service_date: dates.out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = act(original_animal.id, params)

      assert new_animal == %{original_animal | 
                             out_of_service_datestring: dates.iso_next_out_of_service,
                             out_of_service_date: dates.next_out_of_service,
                             lock_version: 2
                           }
    end

    test "update both dates", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        in_service_date: dates.in_service,
        out_of_service_datestring: dates.iso_out_of_service,
        out_of_service_date: dates.out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_next_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = act(original_animal.id, params)

      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_next_in_service,
                             in_service_date: dates.next_in_service,
                             out_of_service_datestring: dates.iso_next_out_of_service,
                             out_of_service_date: dates.next_out_of_service,
                             lock_version: 2
                           }
    end
    
    test "delete out-of-service date", %{dates: dates} do 
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        in_service_date: dates.in_service,
        out_of_service_datestring: dates.iso_out_of_service,
        out_of_service_date: dates.out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => @never}
      new_animal = act(original_animal.id, params)

      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_in_service,
                             in_service_date: dates.in_service,
                             out_of_service_datestring: @never,
                             lock_version: 2
                           }
    end
    
    test "add new out-of-service date", %{dates: dates} do 
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        in_service_date: dates.in_service,
        out_of_service_datestring: @never
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = act(original_animal.id, params)

      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_in_service,
                             in_service_date: dates.in_service,
                             out_of_service_datestring: dates.iso_next_out_of_service,
                             out_of_service_date: dates.next_out_of_service,
                             lock_version: 2
                            }
    end

    test "reject out-of-order-dates", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        in_service_date: dates.in_service,
        out_of_service_datestring: dates.iso_out_of_service,
        out_of_service_date: dates.out_of_service
      )
      #           vv                                       vvvvvv
      params = %{"in_service_datestring" => dates.iso_next_out_of_service,
                 "out_of_service_datestring" => dates.iso_next_in_service}
      #           ^^^^^^                                       ^^
      assert {:error, changeset} = AnimalApi.update(original_animal.id, params, @institution)
      assert ToDate.misorder_error_message in errors_on(changeset).out_of_service_datestring
    end
  end


  describe "optimistic concurrency" do
    setup do
      {string_id, original} = showable_animal_named("Original Bossie")

      update = fn animal, name ->
        params = params_except(original, %{
            "name" => name,
            "lock_version" => to_string(animal.lock_version)})
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

  defp dated_animal(opts) do
    id = Available.animal_id(opts)
    AnimalApi.showable!(id, @institution)
  end

  defp params_except(animal, overrides) do
    from_animal =
      %{"name" => animal.name,
        "lock_version" => animal.lock_version,
        "in_service_datestring" => animal.in_service_datestring,
        "out_of_service_datestring" => animal.out_of_service_datestring
       }
    Map.merge(from_animal, overrides)
  end

  defp showable_animal_named(name) do
    id = Available.animal_id(name: name)
    {to_string(id),
     AnimalApi.showable!(id, @institution)
    }
  end
end
