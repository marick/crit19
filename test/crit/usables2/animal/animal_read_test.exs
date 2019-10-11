defmodule Crit.Usables.Animal.AnimalReadTest do
  use Crit.DataCase
  alias Crit.Usables.{Animal, AnimalApi, ServiceGap}
  alias Crit.Usables.Hidden.AnimalServiceGap
  alias Ecto.Datespan
  alias Crit.Sql

  setup do
    base = %Animal{
      name: "Bossie",
      species_id: @bovine_id,
      lock_version: 1
    }
    %{id: id} = Sql.insert!(base, @institution)
    # There is always an in-service gap
    add_service_gap_for_animal(id, Datespan.strictly_before(@date))
    [id: id]
  end

  describe "getting a showable animal from its id" do 
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


  def add_service_gap_for_animal(animal_id, datespan) do
    gap = %ServiceGap{gap: datespan,
                      reason: "testing"
                     }
    %{id: gap_id} = Sql.insert!(gap, @institution)

    join_record = %AnimalServiceGap{animal_id: animal_id, service_gap_id: gap_id}
    Sql.insert!(join_record, @institution)
  end
end
