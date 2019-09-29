defmodule Crit.Usables.Show.AnimalTest do
  use Crit.DataCase
  alias Crit.Usables.Read
  alias Crit.Usables.Show
  alias Ecto.Datespan

  # Most tests are indirect

  @id 5
  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2011-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

  describe "conversion" do
    setup do
      base = %Read.Animal{
        id: @id,
        name: "Bossie",
        species: %Read.Species{name: "bovine"}
      }

      in_service = %Read.ServiceGap{gap: Datespan.strictly_before(@date)}
      out_of_service = %Read.ServiceGap{gap: Datespan.date_and_after(@later_date)}

      [base: base, in_service: in_service, out_of_service: out_of_service]
    end

    test "with a single service gap",
      %{base: base, in_service: in_service} do 

      result =
        base
        |> Map.put(:service_gaps, [in_service])
        |> Show.Animal.convert

      assert result.id == @id
      assert result.name == "Bossie"
      assert result.species_name == "bovine"
      assert result.in_service_date == @iso_date
      assert result.out_of_service_date == "never"
    end
    
    test "with two service gaps",
      %{base: base, in_service: in_service, out_of_service: out_of_service} do 
      result =
        base
        |> Map.put(:service_gaps,[out_of_service, in_service])
        |> Show.Animal.convert
        
      assert result.id == @id
      assert result.name == "Bossie"
      assert result.species_name == "bovine"
      assert result.in_service_date == @iso_date
      assert result.out_of_service_date == @later_iso_date
    end
    

  end
  

end
