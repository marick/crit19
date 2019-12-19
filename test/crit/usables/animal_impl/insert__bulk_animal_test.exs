defmodule Crit.Usables.AnimalImpl.InsertBulkAnimalTest do
  use Crit.DataCase
  alias Crit.Usables.AnimalImpl.BulkCreationTransaction 
  alias Crit.Usables.Schemas.{Animal,BulkAnimal}
  alias Ecto.Datespan

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

    test "some changes are distributed to each of the created changesets" do
      [one_cs, two_cs] = make_changeset(@iso_date, @later_iso_date)

      one_cs
      |> assert_changes(species_id: 1,
                        span: Datespan.customary(@date, @later_date))
      assert one_cs.changes.name == "one"
      assert one_cs.data == %Animal{}

      assert_copy(one_cs.changes, two_cs.changes, except: [:name])
    end

    test "only the name changes" do
      [one_cs, two_cs] = make_changeset(@iso_date, @later_iso_date)

      assert_change(one_cs, name: "one")
      assert_change(two_cs, name: "two")
    end

    test "the data part is an empty animal - causing creation" do
      [one_cs, two_cs] = make_changeset(@iso_date, @later_iso_date)

      assert one_cs.data == %Animal{}
      assert two_cs.data == %Animal{}
    end
    
    test "out_of_service_datestring can be never" do 
      [one_cs, two_cs] = make_changeset(@iso_date, @never)

      span = Datespan.inclusive_up(@date)
      assert_change(one_cs, span: span)
      assert_change(two_cs, span: span)
    end
  end
end
  
