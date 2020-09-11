defmodule Crit.Reservations.ReservationApiTest do
  use Crit.DataCase
  alias Crit.Reservations.ReservationApi
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Schemas.Reservation
  import Crit.RepoState

  def typical_params do 
    ReservationFocused.ignored_animal("Ignored animal", @bovine_id)
    ReservationFocused.ignored_procedure("Ignored procedure", @bovine_id)

    ReservationFocused.ready_to_reserve!(@bovine_id,
      ["Jeff", "bossie"], ["procedure 1", "procedure 2"],
      responsible_person: "dster")
  end

  def assert_expected_reservation(reservation, ready) do
    assert_fields(reservation,
      species_id: ready.species_id,
      timeslot_id: ready.timeslot_id,
      responsible_person: "dster",
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
      |> ok_content
      |> assert_expected_reservation(ready)
    end
  end

  describe "fetching by id" do
    setup do
      repo = 
        empty_repo()
        |> reservation_for(["bossie"], ["procedure1"],
             date: @date_1, name: "reservation")
      [repo: repo]
    end

    test "by id", %{repo: repo} do
      ReservationApi.get!(repo.reservation.id, @institution)
      |> assert_shape(%Reservation{})
      |> assert_same_map(repo.reservation, ignoring: [:uses])
      |> refute_assoc_loaded(:uses)
    end
  end

  describe "fetching by dates" do
    setup do
      empty_repo()
      |> reservation_for(["lower boundary"], ["procedure1"], date: @date_1)
      |> reservation_for(["upper boundary"], ["procedure2"], date: @date_2)
      |> reservation_for(["out of scope"], ["procedure3"], date: @date_3)
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
