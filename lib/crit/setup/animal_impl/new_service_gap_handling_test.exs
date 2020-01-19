defmodule Crit.Setup.Schemas.AnimalApi.ReadFunctionsTest do
  use Crit.DataCase, async: true
  alias Crit.Setup.Schemas.{Animal, ServiceGap}
  alias Ecto.Changeset

  describe "form changeset" do
    test "basics" do
      animal = Factory.build(:animal, service_gaps: [])
      %Changeset{} = changeset = Animal.form_changeset(animal)
      assert_no_changes(changeset)
    end

    test "adds an empty service gap" do
      service_gap = Factory.build(:service_gap, id: @id__)
      animal = Factory.build(:animal, service_gaps: [service_gap])

      Animal.form_changeset(animal).data
      |> assert_field(service_gaps: [%ServiceGap{}, service_gap])
    end
    
    test "adds an empty service gap even if no service gaps" do
      animal = Factory.build(:animal, service_gaps: [])

      Animal.form_changeset(animal).data
      |> assert_field(service_gaps: [%ServiceGap{}])
    end

  end
end
