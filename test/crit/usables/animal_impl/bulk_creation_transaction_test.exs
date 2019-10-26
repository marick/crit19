defmodule Crit.Usables.AnimalImpl.BulkCreationTransactionTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalImpl.BulkCreationTransaction 
  alias Crit.Usables.Schemas.{Animal,BulkAnimal}
  # alias Ecto.Datespan

  describe "breaking a valid changeset into changesets for insertion" do
    defp make_changeset(in_service_string, out_of_service_string) do
      base = %{
        names: "one, two",
        species_id: "1",
        timezone: "America/Chicago",
      }
      base
      |> Map.put(:in_service_datestring,  in_service_string)
      |> Map.put(:out_of_service_datestring, out_of_service_string)
      |> BulkAnimal.creation_changeset
      |> BulkCreationTransaction.changeset_to_changesets
    end
    
    test "has no out-of-service date" do 
      [one_cs, two_cs] = make_changeset(@iso_date, @never)
      
      assert one_cs.changes.name == "one"
      assert one_cs.changes.species_id == 1
      assert one_cs.changes.in_service_date == @date
      refute one_cs.changes[:out_of_service_date]
      assert one_cs.data == %Animal{}
      
      assert two_cs.changes.name == "two"
      # Rest is the same
      assert two_cs.changes.species_id == 1
      assert two_cs.changes.in_service_date == @date
      refute two_cs.changes[:out_of_service_date]
      assert two_cs.data == %Animal{}
    end

    test "has an out-of-service date" do 
      [one_cs, _two_cs] = make_changeset(@iso_date, @later_iso_date)
      
      assert one_cs.changes.in_service_date == @date
      assert one_cs.changes.out_of_service_date == @later_date
    end
    
  end
end
  
