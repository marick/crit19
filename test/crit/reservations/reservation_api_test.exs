defmodule Crit.Reservations.ReservationApiTest do
  use Crit.DataCase
  alias Crit.Reservations.ReservationApi
  alias Crit.Setup.InstitutionApi
  alias Crit.Exemplars.ReservationFocused
  alias CritWeb.Reservations.AfterTheFactStructs.State

  @timeslot_id ReservationFocused.some_timeslot_id
  @span InstitutionApi.timespan(@date_1, @timeslot_id, @institution)
  
  def typical_params do 
    animal_ids =
      ReservationFocused.inserted_animal_ids(["Jeff", "bossie"], @bovine_id)
    ReservationFocused.ignored_animal("Ignored animal", @bovine_id)
    
    procedure_ids =
      ReservationFocused.inserted_procedure_ids(
        ["procedure 1", "procedure 2"], @bovine_id)
    ReservationFocused.ignored_procedure("Ignored procedure", @bovine_id)
    
    %State{
      species_id: @bovine_id,
      timeslot_id: @timeslot_id,
      span: @span,
      chosen_animal_ids: animal_ids,
      chosen_procedure_ids: procedure_ids
    }
  end

  def assert_expected_reservation(reservation) do
    assert_fields(reservation,
      species_id: @bovine_id,
      timeslot_id: @timeslot_id,
      span: @span)

    [bossie, jeff] = reservation.animal_pairs
    assert {"bossie", _id}  = bossie
    assert {"Jeff", _id} = jeff

    [proc1, proc2] = reservation.procedure_pairs
    assert {"procedure 1", _id} = proc1
    assert {"procedure 2", _id} = proc2
  end

  describe "insertion" do
    test "we assume success" do
      typical_params()
      |> ReservationApi.create(@institution)
      |> ok_payload
      |> assert_expected_reservation
    end
  end

  describe "updatable!" do
    setup do
      %{id: reservation_id} = 
        typical_params()
        |> ReservationApi.create(@institution)
        |> ok_payload
      
      [reservation_id: reservation_id]
    end

    test "by id", %{reservation_id: reservation_id} do
      ReservationApi.updatable!(reservation_id, @institution)
      |> assert_expected_reservation
    end
  end
end
