defmodule Crit.Reservations.ReservationApiTest do
  use Crit.DataCase
  alias Crit.Reservations.ReservationApi
  alias Crit.Exemplars.ReservationFocused

  def typical_params do 
    ReservationFocused.ignored_animal("Ignored animal", @bovine_id)
    ReservationFocused.ignored_procedure("Ignored procedure", @bovine_id)

    ReservationFocused.ready_to_reserve!(@bovine_id,
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

    {[bossie_name, _], [proc_name, _]} =
      ReservationApi.all_names(reservation.id, @institution)
    assert "bossie" == bossie_name
    assert "procedure 1" == proc_name
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

  describe "fetching by id" do
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
  end

  describe "fetching by dates" do
    setup do
      ReservationFocused.reserved!(@bovine_id,
        ["lower boundary"], ["procedure1"],
        date: @date_1)
      ReservationFocused.reserved!(@bovine_id,
        ["upper boundary"], ["procedure2"],
        date: @date_2)
      ReservationFocused.reserved!(@bovine_id,
        ["out of scope"], ["procedure3"],
        date: @date_3)
      :ok
    end
    
    test "by date" do
      assert [lower, upper] =
        ReservationApi.on_dates(@date_1, @date_2, @institution)

      assert lower.date == @date_1
      assert upper.date == @date_2
    end
  end

end
