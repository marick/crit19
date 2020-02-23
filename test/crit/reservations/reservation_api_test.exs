defmodule Crit.Reservations.ReservationApiTest do
  use Crit.DataCase
  alias Crit.Reservations.ReservationApi
  alias Crit.Exemplars.ReservationFocused

  def typical_params do 
    ReservationFocused.ignored_animal("Ignored animal", @bovine_id)
    ReservationFocused.ignored_procedure("Ignored procedure", @bovine_id)

    ReservationFocused.ready_to_insert(@bovine_id,
      ["Jeff", "bossie"], ["procedure 1", "procedure 2"])
  end

  def assert_expected_reservation(reservation, ready) do
    assert_fields(reservation,
      species_id: ready.species_id,
      timeslot_id: ready.timeslot_id,
      date: ready.date,
      span: ready.span)

    {[bossie, jeff], [proc1, proc2]} =
      ReservationApi.all_used(reservation.id, @institution)
    assert "bossie" == bossie.name
    assert "Jeff" == jeff.name

    assert "procedure 1" == proc1.name
    assert "procedure 2" == proc2.name
  end

  describe "insertion" do
    test "we assume success" do
      ready = typical_params()

      ready
      |> ReservationApi.create(@institution)
      |> ok_payload
      |> assert_expected_reservation(ready)
    end
  end

  describe "fetching" do
    setup do
      ready = typical_params()
      %{id: reservation_id} =
        ready
        |> ReservationApi.create(@institution)
        |> ok_payload
      
      [reservation_id: reservation_id, ready: ready]
    end

    test "by id", %{reservation_id: reservation_id, ready: ready} do
      ReservationApi.get!(reservation_id, @institution)
      |> assert_expected_reservation(ready)
    end

    test "by date", %{ready: ready} do
      assert [only] = ReservationApi.reservations_on_date(ready.date, @institution)
      assert_expected_reservation(only, ready)
    end
  end
end
