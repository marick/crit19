defmodule Crit.Usables.Animal.AnimalReadTest do
  use Crit.DataCase
  alias Crit.Usables.{Animal, AnimalApi}
  alias Ecto.Datespan
  alias Crit.Sql

  @id 5

  setup do
    base = %Animal{
      name: "Bossie",
      species_id: @bovine_id,
      lock_version: 1
    }
    %{id: id} = Sql.insert!(base, @institution)
    [id: id]
  end

  describe "getting an animal from its id" do 
    test "basic conversions", %{id: id} do
      animal = AnimalApi.showable!(id, @institution)

      assert animal.name == "Bossie"
      assert animal.lock_version == 1
      assert animal.species_id == @bovine_id
      assert animal.species_name == @bovine
    end
  end
end

  #     in_service = %Write.ServiceGap{gap: Datespan.strictly_before(@date)}
  #     out_of_service = %Write.ServiceGap{gap: Datespan.date_and_after(@later_date)}

  #     [base: base, in_service: in_service, out_of_service: out_of_service]
  #   end

  #   test "with a single service gap",
  #     %{base: base, in_service: in_service} do 

  #     result =
  #       base
  #       |> Map.put(:service_gaps, [in_service])
  #       |> Show.Animal.convert

  #     assert result.id == @id
  #     assert result.name == "Bossie"
  #     assert result.species_name == @bovine
  #     assert result.species_id == @bovine_id
  #     assert result.in_service_date == @iso_date
  #     assert result.out_of_service_date == @never
  #     assert result.lock_version == 1
  #   end
    
  #   test "with two service gaps",
  #     %{base: base, in_service: in_service, out_of_service: out_of_service} do 
  #     result =
  #       base
  #       |> Map.put(:service_gaps,[out_of_service, in_service])
  #       |> Show.Animal.convert
        
  #     assert result.id == @id
  #     assert result.name == "Bossie"
  #     assert result.species_name == @bovine
  #     assert result.species_id == @bovine_id
  #     assert result.in_service_date == @iso_date
  #     assert result.out_of_service_date == @later_iso_date
  #     assert result.lock_version == 1
  #   end
  # end
