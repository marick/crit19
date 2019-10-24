defmodule Crit.Usables.AnimalImpl.UpdateTransactionTest do
  use Crit.DataCase
  alias Crit.Usables.Schemas.{Animal, ServiceGap}
  alias Crit.Usables.AnimalImpl.UpdateTransaction
  alias Crit.Usables.AnimalImpl.UpdateTransaction.Testable
  alias Crit.Exemplars.Available
  alias Crit.Usables.AnimalApi
  alias Ecto.Datespan
  alias Crit.Sql

  @in_service_id 3333
  @old_in_service_datestring "2011-01-01"
  @new_in_service_datestring "2022-02-02"
  @new_in_service ServiceGap.in_service_gap(~D[2022-02-02])

  @out_of_service_id 9999
  @old_out_of_service_datestring "2033-03-03"
  @new_out_of_service_datestring "2044-04-04"


  describe "splitting an-service changeset" do
    test "splitting an-service changeset" do
      id = Available.animal_id(in_service_date: @old_in_service_datestring)
      animal = AnimalApi.showable!(id, @institution)
      changeset = Animal.update_changeset(animal, %{"in_service_date" => @new_in_service_datestring})

      assert [cset] = Testable.in_service_gap_changeset(changeset)

      assert Datespan.equal?(cset.changes.gap, @new_in_service.gap)

      sg_id = List.first(animal.service_gaps).id
      assert cset.data.id == sg_id

      IO.inspect Sql.update(cset, @institution)
    end
  end
end
