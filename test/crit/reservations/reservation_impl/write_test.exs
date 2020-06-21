defmodule Crit.Reservations.ReservationImpl.WriteTest do
  use Crit.DataCase
  alias Crit.Reservations.ReservationImpl.Write
  alias Crit.Reservations.ReservationApi
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Setup.InstitutionApi
  alias Crit.Exemplars.ReservationFocused
  alias CritWeb.Reservations.AfterTheFactStructs.TaskMemory
  import Crit.Background

  @date @date_3
  @timeslot_id ReservationFocused.morning_timeslot

  # Names for the data in question
  @animal__two_conflicts "service gap and use animal"   
  @animal__only_use_conflict "reserved animal"
  @procedure__used_twice "new procedure"

  # two conflicting reservations and a conflicting service gap
  # (Unlikely in practice)
  setup do 
    b =
      background()
      |> reservation_for("vcm103",
                         [@animal__two_conflicts, @animal__only_use_conflict],
                         ["any old procedure", @procedure__used_twice],
                         date: @date) 
      |> service_gap_for(@animal__two_conflicts, starting: @date)

    [background: b]
  end

  test "create, noting conflicts", %{background: b} do
    # act
    desired =
      reservation_data(b,
        @date,
        [@animal__two_conflicts, @animal__only_use_conflict],
        [@procedure__used_twice])
    assert {:ok, created, conflicts} =
      Write.create_noting_conflicts(desired, @institution)

    assert_stored_matches_desire(desired, 
      ReservationApi.get!(created.id, @institution),
      ReservationApi.all_used(created.id , @institution))

    assert_names_are(conflicts.service_gap, [@animal__two_conflicts])
    assert_names_are(conflicts.use, [@animal__only_use_conflict, @animal__two_conflicts])
  end

  def reservation_data(b, date, animal_names, procedure_names) do
    %TaskMemory{
      # When the reservation is
      date:  date,
      timeslot_id: @timeslot_id, 
      span: InstitutionApi.timespan(date, @timeslot_id, @institution),

      chosen_animal_ids: ids(b, :animal, animal_names),
      chosen_procedure_ids: ids(b, :procedure, procedure_names),

      # Not important but required
      species_id: b.species_id,
      responsible_person: "anyone"
    }
  end

  # ----------------------------------------------------------------

  defp assert_stored_matches_desire(desired,
    %Reservation{} = reservation, all_used) do
    
    assert_fields(reservation,
      species_id: desired.species_id,
      date: desired.date,
      span: desired.span,
      timeslot_id: desired.timeslot_id)
    
    {[animal__only_use_conflict, service_gap], [procedure]} = all_used
    assert animal__only_use_conflict.name == @animal__only_use_conflict
    assert service_gap.name == @animal__two_conflicts
    assert procedure.name == @procedure__used_twice
  end

  defp assert_names_are(actual, expected),
    do: assert expected == EnumX.names(actual)

end  
