defmodule Crit.Usables.AnimalApi.UpdateTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Exemplars
  alias Crit.Usables.FieldConverters.ToDate

  defp update_for_success(id, params) do
    assert {:ok, new_animal} =
      AnimalApi.update(to_string(id), params, @institution)
    new_animal
  end

  defp update_for_error(id, params) do
    assert {:error, changeset} = AnimalApi.update(id, params, @institution)
    errors_on(changeset)
  end

  describe "updating the name and common behaviors" do
    test "success" do
      original = showable_animal_named("Original Bossie")
      params = params_except(original, %{"name" => "New Bossie"})

      update_for_success(original.id, params)
      |> assert_fields(name: "New Bossie", lock_version: 2)
      |> assert_copy(original,
                     except: [:name, :lock_version, :updated_at])
      |> assert_copy(AnimalApi.showable!(original.id, @institution),
                     except: [:updated_at])
    end

    test "unique name constraint violation produces changeset" do
      original = showable_animal_named("Original Bossie")
      showable_animal_named("already exists")
      params = params_except(original, %{"name" => "already exists"})

      assert "has already been taken" in update_for_error(original.id, params).name
    end
  end


  describe "updating service dates" do
    setup do
      [dates: Exemplars.Date.service_dates()]
    end
    
    test "update in-service date", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: "never"
      )
        
      params = %{"in_service_datestring" => dates.iso_next_in_service,
                 "out_of_service_datestring" => "never"}
      new_animal = update_for_success(original_animal.id, params)
      assert new_animal == %{original_animal | 
                             in_service_datestring: dates.iso_next_in_service,
                             in_service_date: dates.next_in_service,
                             lock_version: 2
                           }
    end

    test "update out-of-service date", %{dates: dates} do
      animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: dates.iso_out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = update_for_success(animal.id, params)

      assert new_animal == %{animal | 
                             out_of_service_datestring: dates.iso_next_out_of_service,
                             out_of_service_date: dates.next_out_of_service,
                             lock_version: 2
                           }
    end

    test "update both dates", %{dates: dates} do
      original_animal = dated_animal(
        in_service_datestring: dates.iso_in_service,
        out_of_service_datestring: dates.iso_out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_next_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = update_for_success(original_animal.id, params)

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
        out_of_service_datestring: dates.iso_out_of_service
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => @never}
      new_animal = update_for_success(original_animal.id, params)

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
        out_of_service_datestring: @never
      )
      params = %{"in_service_datestring" => dates.iso_in_service,
                 "out_of_service_datestring" => dates.iso_next_out_of_service}
      new_animal = update_for_success(original_animal.id, params)

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
        out_of_service_datestring: dates.iso_out_of_service
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
      original = showable_animal_named("Original Bossie")

      update = fn animal, name ->
        params = params_except(original, %{
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
    with_in_service =
      Keyword.put(opts, :in_service,
        Date.from_iso8601!(Keyword.get(opts, :in_service_datestring)))

    with_out_of_service =
      case outstring = Keyword.get(opts, :out_of_service_datestring) do 
        @never -> with_in_service
        _ -> Keyword.put(with_in_service, :out_of_service,
               Date.from_iso8601!(outstring))
      end
    
    id = Exemplars.Available.animal_id(with_out_of_service)
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
    id = Exemplars.Available.animal_id(name: name)
    AnimalApi.showable!(id, @institution)
  end
end
