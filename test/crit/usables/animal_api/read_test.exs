defmodule Crit.Usables.Schemas.AnimalApi.ReadTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Schemas.{Animal, ServiceGap}
  alias Crit.Usables.HiddenSchemas.AnimalServiceGap
  alias Ecto.Datespan
  alias Crit.Sql

  describe "getting a showable animal from its id" do
    setup :one_animal_setup
    
    test "basic conversions", %{id: id} do
      animal = AnimalApi.showable!(id, @institution)

      assert animal.name == "Bossie"
      assert animal.lock_version == 1
      assert animal.species_id == @bovine_id
      assert animal.species_name == @bovine
    end

    test "with a single service gap", %{id: id} do
      animal = AnimalApi.showable!(id, @institution)
      assert animal.in_service_date == @iso_date
      assert animal.out_of_service_date == @never
    end

    test "with an out-of-service gap", %{id: id} do
      add_service_gap_for_animal(id, Datespan.date_and_after(@later_date))
      animal = AnimalApi.showable!(id, @institution)
      assert animal.in_service_date == @iso_date
      assert animal.out_of_service_date == @later_iso_date
    end

    test "no such id" do
      assert_raise KeyError, fn -> 
        AnimalApi.showable!(83483, @institution)
      end
    end
  end

  describe "fetching an animal by something other than an id" do
    setup :one_animal_setup

    test "fetching by name" do
      assert animal = AnimalApi.showable_by(:name, "Bossie", @institution)
      assert is_integer(animal.id)
      assert animal.name == "Bossie"
      assert animal.species_name == @bovine
    end

    test "fetching by name is case independent" do
      assert animal = AnimalApi.showable_by(:name, "bossie", @institution)
      assert is_integer(animal.id)
      assert animal.name == "Bossie"
      assert animal.species_name == @bovine
    end

    test "errors return nil" do
      assert nil == AnimalApi.showable_by(:name, "lossie", @institution)
    end
  end

  describe "fetching a number of animals" do
    setup :three_animal_setup

    test "ids_to_animals returns animals in alphabetical order", %{ids: ids} do
      assert [alpha, bossie, jake] = AnimalApi.ids_to_animals(ids, @institution)

      assert alpha.name == "Alpha"
      assert alpha.species_name == @bovine
      assert alpha.in_service_date == @iso_date
      assert alpha.out_of_service_date == @never

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

    test "fetch everything" do 
      assert [alpha, bossie, jake] = AnimalApi.all(@institution)
      assert alpha.name == "Alpha"
      assert bossie.name == "bossie"
      assert jake.name == "Jake"
    end
  end

  def one_animal_setup(_) do
    params = %Animal{
      name: "Bossie",
      species_id: @bovine_id,
      lock_version: 1
    }
    %{id: id} = Sql.insert!(params, @institution)
    # There is always an in-service gap
    add_service_gap_for_animal(id, Datespan.strictly_before(@date))
    [id: id]
  end

  def three_animal_setup(_) do
    params = %{
      "species_id" => @bovine_id,
      "names" => "bossie, Jake, Alpha",
      "start_date" => @iso_date,
      "end_date" => @never
    }

    {:ok, animals} = AnimalApi.create_animals(params, @institution)
    [ids: EnumX.ids(animals)]
  end

  def add_service_gap_for_animal(animal_id, datespan) do
    gap = %ServiceGap{gap: datespan,
                      reason: "testing"
                     }
    %{id: gap_id} = Sql.insert!(gap, @institution)

    join_record = %AnimalServiceGap{animal_id: animal_id, service_gap_id: gap_id}
    Sql.insert!(join_record, @institution)
  end
end
