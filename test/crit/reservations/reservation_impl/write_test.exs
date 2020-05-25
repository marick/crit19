defmodule Crit.Reservations.ReservationImpl.WriteTest do
  use Crit.DataCase
  alias Crit.Reservations.ReservationImpl.Write
  alias Crit.Reservations.ReservationApi
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Setup.InstitutionApi
  alias Crit.Setup.ProcedureApi
  alias Ecto.Datespan
  alias Crit.Exemplars.{Available, ReservationFocused}
  alias CritWeb.Reservations.AfterTheFactStructs.TaskMemory

  @date @date_3
  @timeslot_id ReservationFocused.morning_timeslot
  @times_that_matter %TaskMemory{
    date: @date,
    species_id: @bovine_id,
    timeslot_id: @timeslot_id, 
    span: InstitutionApi.timespan(@date, @timeslot_id, @institution),
  }

  # Names for the data in question
  @two_conflicts "service gap and use animal"   
  @just_use_conflict "other"
  @procedure_name "new procedure"

  # two conflicting reservations and a conflicting service gap
  # (Unlikely in practice)
  
  def arrange(_) do
    two_conflicts = Available.bovine(@two_conflicts, @date)
    service_gap_including_desired_date!(two_conflicts, @date)
    reserved_on_desired_date!(
      two_conflicts, @date, ReservationFocused.morning_timeslot)

    just_use_conflict = Available.bovine(@just_use_conflict, @date)
    [two_conflicts, just_use_conflict]
    |> reserved_on_desired_date!(@date, ReservationFocused.morning_timeslot)

    procedure = chosen_procedure()

    desired =
      %{ @times_that_matter |
         responsible_person: "anyone",
         chosen_animal_ids: [two_conflicts.id, just_use_conflict.id],
         chosen_procedure_ids: [procedure.id]
       }

    [desired: desired]
  end

  setup :arrange

  test "create, noting conflicts", %{desired: desired} do
    # act
    assert {:ok, %Reservation{id: reservation_id}, conflicts} =
      Write.create_noting_conflicts(desired, @institution)

    assert_stored_matches_desire(desired, 
      ReservationApi.get!(reservation_id, @institution),
      ReservationApi.all_used(reservation_id, @institution))

    assert_names_are(conflicts.service_gap, [@two_conflicts])
    assert_names_are(conflicts.use, [@just_use_conflict, @two_conflicts])
  end

  # ------------------------------------------------------------------------

  defp assert_stored_matches_desire(desired,
    %Reservation{} = reservation, all_used) do
    
    assert_fields(reservation,
      species_id: desired.species_id,
      date: desired.date,
      span: desired.span,
      timeslot_id: desired.timeslot_id)
    
    {[just_use_conflict, service_gap], [procedure]} = all_used
    assert just_use_conflict.name == @just_use_conflict
    assert service_gap.name == @two_conflicts
    assert procedure.name == @procedure_name
  end

  defp assert_names_are(actual, expected),
    do: assert expected == EnumX.names(actual)

  # ------------------------------------------------------------------------

  defp chosen_procedure() do
    [id] = ReservationFocused.inserted_procedure_ids([@procedure_name], @bovine_id)
    ProcedureApi.one_by_id(id, @institution, preload: [:frequency])
  end

  defp reserved_on_desired_date!(animals, date, timeslot_id) when is_list(animals) do
    ReservationFocused.reserved!(@bovine_id, EnumX.names(animals), ["procedure"],
      timeslot_id: timeslot_id,
      date: date)
  end
  
  defp reserved_on_desired_date!(animal, date, timeslot_id),
    do: reserved_on_desired_date!([animal], date, timeslot_id)

  defp service_gap_including_desired_date!(animal, date),
    do: service_gap!(
          animal,
          Datespan.customary(date, Date.add(date, 1)))
  
  defp service_gap!(animal, span) do 
    Factory.sql_insert!(:service_gap, [animal_id: animal.id, span: span],
      @institution)
  end
end  
