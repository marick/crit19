defmodule Crit.Usables.Api.AnimalTest do
  use Crit.DataCase
  alias Crit.Usables

  @iso_date "2001-09-05"
  # @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2011-09-05"
  # @later_date Date.from_iso8601!(@later_iso_date)

  @species_id 1

  @basic_params %{
    "species_id" => @species_id,
    "names" => "Bossie, Jake",
    "start_date" => @iso_date,
    "end_date" => "never"
  }

  describe "bulk animal creation" do

    test "an error produces a changeset" do
      params =
        @basic_params
        |> Map.put("start_date", @later_iso_date)
        |> Map.put("end_date", @iso_date)
        |> Map.put("names", ",")
        
      assert {:error, changeset} = Usables.create_animals(params, @institution)

      errors = errors_on(changeset)
      assert [_message] = errors.end_date
      assert [_message] = errors.names
    end

    test "without an error, we insert a network" do
      {:ok, [bossie, jake]} = Usables.create_animals(@basic_params, @institution)

      check = fn returned ->
        fetched = Usables.get_complete_animal!(returned.id, @institution)
        assert fetched.id == returned.id
        assert fetched.name == returned.name
        assert length(returned.service_gaps) == 1
        assert returned.species.name == "bovine"
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


  describe "animal creation" do
    test "a 'complete' animal is returned" do
      assert {:ok, [bossie, jake]} =
        Usables.create_animal(@basic_params, @institution)

      assert bossie.name == "Bossie"
      assert jake.name == "Jake"

      assert bossie.species.id == @species_id
      assert jake.species.id == @species_id

      assert Ecto.assoc_loaded?(bossie.service_gaps)
      assert Ecto.assoc_loaded?(jake.service_gaps)
    end

  end

  describe "fetching an animal" do
    setup do 
      Usables.create_animal(@basic_params, @institution)
      []
    end  
    
    test "fetching by name" do
      assert animal = Usables.get_complete_animal_by_name("Bossie", @institution)
      assert animal.name == "Bossie"
      assert Ecto.assoc_loaded?(animal.service_gaps)
    end

    test "errors return nil" do
      assert nil == Usables.get_complete_animal_by_name("lossie", @institution)
    end

    test "fetch by id" do
      id = Usables.get_complete_animal_by_name("Bossie", @institution).id
      animal = Usables.get_complete_animal!(id, @institution)
                        
      assert animal.name == "Bossie"
      assert Ecto.assoc_loaded?(animal.service_gaps)
    end
    
    test "no such id" do
      assert_raise KeyError, fn -> 
        Usables.get_complete_animal!(83483, @institution)
      end
    end
  end

  describe "fetching a number of animals" do 
    setup do
      params = Map.put(@basic_params, "names", "Bossie, Jake, Alpha")

      {:ok, animals} = Usables.create_animal(params,@institution)
      [ids: Enum.map(animals, &(&1.id))]
    end


    test "available_species returns animals in alphabetical order", %{ids: ids} do
      assert [alpha, bossie, jake] = Usables.ids_to_animals(ids, @institution)

      assert alpha.name == "Alpha"
      assert alpha.species.id == @species_id
      assert Ecto.assoc_loaded?(alpha.service_gaps)

      assert bossie.name == "Bossie"
      assert jake.name == "Jake"
    end

    test "bad ids are silently ignored", %{ids: ids} do
      new_ids = [387373 | ids]
      
      assert [alpha, bossie, jake] = Usables.ids_to_animals(new_ids, @institution)
      assert alpha.name == "Alpha"
      assert bossie.name == "Bossie"
      assert jake.name == "Jake"
    end
  end
end
