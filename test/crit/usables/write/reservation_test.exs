defmodule Crit.Usables.Write.ReservationTest do
  use Crit.DataCase
  alias Crit.Usables.Write

  describe "changeset" do
    test "required fields are checked" do
      errors =
        %Write.Reservation{}
        |> Write.Reservation.changeset(%{})
        |> errors_on

      assert errors.animal_ids
      assert errors.procedure_ids
      assert errors.start_date
      assert errors.start_time
      assert errors.minutes
    end

    test "appropriate conversions are done" do
      changeset = 
        %Write.Reservation{}
        |> Write.Reservation.changeset(%{start_date: "2019-11-12",
                                        start_time: "23:50:00",
                                        minutes: "5"})
      assert changeset.changes.start_date == ~D{2019-11-12}
      assert changeset.changes.start_time == ~T{23:50:00}
      assert changeset.changes.minutes == 5
    end
  end

  describe "insertion" do
    test "success" do
      # attrs = %{"name" => "physical examinination"}
      # {:ok, %Write.Reservation{id: _id}} = Write.Reservation.insert(attrs, @institution)
    end
  end
    

end
