defmodule Crit.Usables.Schemas.AnimalApi.ReadTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.{Animal}
  alias Crit.Sql

  describe "getting a updatable animal from its id" do
    setup :two_animals_setup
    
    test "basic conversions",
      %{never_out_of_service_id: id} do
      animal = AnimalApi.updatable!(id, @institution)

      assert animal.name == "Never out"
      assert animal.lock_version == 1
      assert animal.species_id == @bovine_id
      assert animal.species_name == @bovine
    end

    test "with only an in-service date",
      %{never_out_of_service_id: id} do
      animal = AnimalApi.updatable!(id, @institution)
      assert animal.in_service_datestring == @iso_date
      assert animal.out_of_service_datestring == @never
    end

    test "with an out-of-service date", %{goes_out_of_service_id: id} do
      animal = AnimalApi.updatable!(id, @institution)
      assert animal.in_service_datestring == @iso_date
      assert animal.out_of_service_datestring == @later_iso_date
    end

    test "no such id" do
      assert_raise KeyError, fn -> 
        AnimalApi.updatable!(83483, @institution)
      end
    end

    test "add service gap conversion" do
      # Create an animal
      # Add a service gap
      # check that the gap is returned AND that the virtual fields are
      # filled in.
    end
  end

  describe "fetching an animal by something other than an id" do

    setup :two_animals_setup

    test "fetching by name" do
      assert animal = AnimalApi.updatable_by(:name, "Never out", @institution)
      assert is_integer(animal.id)
      assert animal.name == "Never out"
      assert animal.species_name == @bovine
      assert animal.in_service_datestring == @iso_date
    end

    test "fetching by name is case independent" do
      assert animal = AnimalApi.updatable_by(:name, "never ouT", @institution)
      assert is_integer(animal.id)
      assert animal.name == "Never out"
    end

    test "errors return nil" do
      assert nil == AnimalApi.updatable_by(:name, "lossie", @institution)
    end
  end

  describe "fetching a number of animals" do
    setup :three_animal_setup

    test "ids_to_animals returns animals in alphabetical order", %{ids: ids} do
      assert [alpha, bossie, jake] = AnimalApi.ids_to_animals(ids, @institution)

      assert alpha.name == "Alpha"
      assert alpha.species_name == @bovine
      assert alpha.in_service_datestring == @iso_date
      assert alpha.out_of_service_datestring == @never

      assert bossie.name == "bossie"
      assert jake.name == "Jake"
    end

    test "bad ids are silently ignored", %{ids: ids} do
      new_ids = [387373 | ids]
      
      assert [alpha, bossie, jake] = AnimalApi.ids_to_animals(new_ids, @institution)
      assert alpha.name == "Alpha"
      assert bossie.name == "bossie"
      assert jake.name == "Jake"
    end
  end

  describe "fetching several animals" do
    setup :three_animal_setup

    test "fetch everything - again in alphabetical order" do 
      assert [alpha, bossie, jake] = AnimalApi.all(@institution)
      assert alpha.name == "Alpha"
      assert bossie.name == "bossie"
      assert jake.name == "Jake"
    end
  end

  defp two_animals_setup(_) do
    base = %Animal{
      species_id: @bovine_id,
      lock_version: 1,
      in_service_date: @date,
    }
    
    %{id: never_out_of_service_id} =
      base
      |> Map.put(:name, "Never out")
      |> Sql.insert!(@institution)
    
    %{id: goes_out_of_service_id} =
      base
      |> Map.put(:name, "out")
      |> Map.put(:out_of_service_date, @later_date)
      |> Sql.insert!(@institution)
    
    [goes_out_of_service_id: goes_out_of_service_id,
     never_out_of_service_id: never_out_of_service_id]
  end
  
  defp three_animal_setup(_) do
    params = %{
      "species_id" => @bovine_id,
      "names" => "bossie, Jake, Alpha",
      "in_service_datestring" => @iso_date,
      "out_of_service_datestring" => @never
    }

    {:ok, animals} = AnimalApi.create_animals(params, @institution)
    [ids: EnumX.ids(animals)]
  end

end
