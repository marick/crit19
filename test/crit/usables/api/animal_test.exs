defmodule Crit.Usables.Api.AnimalTest do
  use Crit.DataCase
  alias Crit.Usables
  import Pile.Changeset

  @iso_date "2001-09-05"
  @later_iso_date "2011-09-05"

  @species_id 1
  @species_name "bovine"

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
      assert represents_form_errors?(changeset)

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
        # assert length(returned.service_gaps) == 1
        assert returned.species_name == "bovine"
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

  describe "fetching an animal" do
    setup do
      Usables.create_animals(@basic_params, @institution)
      []
    end  
    
    test "fetching by name" do
      assert animal = Usables.get_complete_animal_by_name("Bossie", @institution)
      assert is_integer(animal.id)
      assert animal.name == "Bossie"
      assert animal.species_name == "bovine"
    end

    test "errors return nil" do
      assert nil == Usables.get_complete_animal_by_name("lossie", @institution)
    end

    test "fetch by id" do
      id = Usables.get_complete_animal_by_name("Bossie", @institution).id
      animal = Usables.get_complete_animal!(id, @institution)

      assert animal.id == id
      assert animal.name == "Bossie"
      assert animal.species_name == "bovine"
    end
    
    test "no such id" do
      assert_raise KeyError, fn -> 
        Usables.get_complete_animal!(83483, @institution)
      end
    end
  end

  describe "fetching a number of animals" do 
    setup do
      {:ok, animals} = 
        @basic_params
        |> Map.put("names", "Bossie, Jake, Alpha")
        |> Usables.create_animals(@institution)
      [ids: Enum.map(animals, &(&1.id))]
    end

    test "create_animals returns animals in alphabetical order", %{ids: ids} do
      assert [alpha, bossie, jake] = Usables.ids_to_animals(ids, @institution)

      assert alpha.name == "Alpha"
      assert alpha.species_name == @species_name
      assert alpha.in_service_date == @iso_date
      assert alpha.out_of_service_date == "never"

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
