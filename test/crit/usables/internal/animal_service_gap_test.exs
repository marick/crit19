defmodule Crit.Usables.Internal.AnimalServiceGapTest do
  use Crit.DataCase
  alias Crit.Usables.{Animal, ServiceGap, AnimalServiceGap}
  # import Ecto.Changeset
  alias Crit.Sql

  @iso_date "2001-09-05"
  @date Date.from_iso8601!(@iso_date)

  @later_iso_date "2011-09-05"
  @later_date Date.from_iso8601!(@later_iso_date)

  describe "contributions to a transaction" do
    test "linking animals to service gaps" do 
      species_id = 1
      
      params = %{
        "species_id" => species_id,
        "names" => "Bossie, Jake",
        "start_date" => @iso_date,
        "end_date" => @later_iso_date
      }

      service_gap_ids = ServiceGap.TxPart.params_to_ids(params, @default_short_name)
      animal_ids = Animal.TxPart.params_to_ids(params, @default_short_name)
      
      AnimalServiceGap.cross_product(animal_ids, service_gap_ids)
      |> AnimalServiceGap.TxPart.run(@default_short_name)
      |> IO.inspect
    end
  end
end
