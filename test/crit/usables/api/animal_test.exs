defmodule Crit.Usables.Api.AnimalTest do
  use Crit.DataCase
  alias Crit.Usables
  alias Crit.Usables.Write
  alias Crit.Usables.AnimalApi
  import Ecto.ChangesetX
  alias Crit.Exemplars.Available

  @basic_params %{
    "species_id" => @bovine_id,
    "names" => "Bossie, Jake",
    "start_date" => @iso_date,
    "end_date" => @never
  }

  describe "bulk animal creation" do

    test "an error produces a changeset" do
      params =
        @basic_params
        |> Map.put("start_date", @later_iso_date)
        |> Map.put("end_date", @iso_date)
        |> Map.put("names", ",")
        
      assert {:error, changeset} = Usables.create_animals(params, @institution)
      assert represents_form_errors?(changeset)

      errors = errors_on(changeset)
      assert [_message] = errors.end_date
      assert [_message] = errors.names
    end

    test "without an error, we insert a network" do
      {:ok, [bossie, jake]} = Usables.create_animals(@basic_params, @institution)

      check = fn returned ->
        fetched = AnimalApi.showable!(returned.id, @institution)
        assert fetched.id == returned.id
        assert fetched.name == returned.name
        assert fetched.in_service_date == @iso_date
        assert fetched.out_of_service_date == @never
        assert returned.species_name == @bovine
      end

      check.(bossie)
      check.(jake)
    end

    test "constraint problems are detected last" do
      {:ok, [_bossie, _jake]} = Usables.create_animals(@basic_params, @institution)
      {:error, changeset} =   Usables.create_animals(@basic_params, @institution)

      assert ~s|An animal named "Bossie" is already in service| in errors_on(changeset).names
    end
  end    

  describe "updating an animal" do
    test "updating the name" do
      {string_id, original} = showable_animal_named("Original Bossie")
      params = %{"name" => "New Bossie",
                 "species_id" => "this should be ignored",
                 "id" => "this should also be ignored"
                }

      assert {:ok, new_animal} =
        Usables.update_animal(string_id, params, @institution)
      
      assert new_animal == %Write.Animal{original |
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
        Usables.update_animal(string_id, params, @institution)

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
        Usables.update_animal(string_id, params, @institution)
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
        Usables.update_animal(string_id, params, @institution)
      end

      assert {:ok, _} = update.("this version wins")
      assert {:error, changeset} = update.("this version wins")

      # Just the one error
      assert [{:optimistic_lock_error, _template_invents_msg}] = changeset.errors

    end

  end

  describe "fetching an animal" do
    setup do
      Usables.create_animals(@basic_params, @institution)
      []
    end  
    
    test "fetching by name" do
      assert animal = Usables.get_complete_animal_by_name("Bossie", @institution)
      assert is_integer(animal.id)
      assert animal.name == "Bossie"
      assert animal.species_name == @bovine
    end

    test "fetching by name is case independent" do
      assert animal = Usables.get_complete_animal_by_name("bossie", @institution)
      assert is_integer(animal.id)
      assert animal.name == "Bossie"
      assert animal.species_name == @bovine
    end

    test "errors return nil" do
      assert nil == Usables.get_complete_animal_by_name("lossie", @institution)
    end

  end

  describe "fetching a number of animals" do 
    setup do
      {:ok, animals} = 
        @basic_params
        |> Map.put("names", "bossie, Jake, Alpha")
        |> Usables.create_animals(@institution)
      [ids: EnumX.ids(animals)]
    end

    test "all returns animals in (case-independent) alphabetical order" do 
      assert [alpha, bossie, jake] = Usables.all_animals(@institution)
    end

    test "ids_to_animals returns animals in alphabetical order", %{ids: ids} do
      assert [alpha, bossie, jake] = Usables.ids_to_animals(ids, @institution)

      assert alpha.name == "Alpha"
      assert alpha.species_name == @bovine
      assert alpha.in_service_date == @iso_date
      assert alpha.out_of_service_date == @never

      assert bossie.name == "bossie"
      assert jake.name == "Jake"
    end

    test "bad ids are silently ignored", %{ids: ids} do
      new_ids = [387373 | ids]
      
      assert [alpha, bossie, jake] = Usables.ids_to_animals(new_ids, @institution)
      assert alpha.name == "Alpha"
      assert bossie.name == "bossie"
      assert jake.name == "Jake"
    end
  end

  defp showable_animal_named(name) do
    id = Available.animal_id(name: name)
    {to_string(id), 
     AnimalApi.showable!(id, @institution)
    }
  end
end
