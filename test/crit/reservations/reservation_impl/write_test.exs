defmodule Crit.Reservations.ReservationImpl.WriteTest do
  use Crit.DataCase
  alias Crit.Reservations.ReservationImpl.Write
  alias Crit.Reservations.ReservationApi
  alias Crit.Setup.InstitutionApi
  alias Ecto.Datespan
  alias Crit.Exemplars.{Available, ReservationFocused}
  alias CritWeb.Reservations.AfterTheFactStructs.State

  @timeslot_id ReservationFocused.morning_timeslot
  @desired %State{
    date: @date_3,
    species_id: @bovine_id,
    timeslot_id: @timeslot_id, 
    span: InstitutionApi.timespan(@date_3, @timeslot_id, @institution),
    responsible_person: "anyone"
  }

  @tag :skip
  test "create, noting conflicts" do
    # two conflicting reservations and a conflicting service gap
    # (Unlikely in practice)
    
    service_gap = Available.bovine("service gap", @date_3)
    service_gap_including_desired_date!(service_gap)
    reserved_on_desired_date!(service_gap, ReservationFocused.morning_timeslot)
    
    other = Available.bovine("other", @date_3)

    IO.inspect @institution

    [service_gap, other]
    |> reserved_on_desired_date!(ReservationFocused.morning_timeslot)

    procedure_ids =
      ReservationFocused.inserted_procedure_ids(["new procedure"], @bovine_id)
    full_description =
      %{ @desired |
         chosen_animal_ids: [service_gap.id, other.id], 
         chosen_procedure_ids: procedure_ids}
    
    assert {:ok, reservation, conflicts} =
      Write.create_noting_conflicts(full_description, @institution)

    freshly_read = ReservationApi.get!(reservation.id, @institution)
    assert_fields(freshly_read,
      species_id: @desired.species_id,
      date: @desired.date,
      span: @desired.span,
      timeslot_id: @desired.timeslot_id)

    {[other_2, service_gap_2], [procedure_2]} =
      ReservationApi.all_used(reservation.id, @institution)
    assert other_2.name == other.name
    assert service_gap_2.name == service_gap.name
    assert procedure_2.name == "new procedure"

    assert conflicts.service_gap == [other.name]
    assert conflicts.use == [other.name, service_gap.name]
  end


  def reserved_on_desired_date!(animals, timeslot_id) when is_list(animals) do
    names = Enum.map(animals, &(&1.name))
    ReservationFocused.reserved!(@bovine_id, names, ["procedure"],
      timeslot_id: timeslot_id,
      date: @date_3)
  end
  
  def reserved_on_desired_date!(animal, timeslot_id),
    do: reserved_on_desired_date!([animal], timeslot_id)

  defp service_gap_including_desired_date!(animal),
    do: service_gap!(animal, Datespan.customary(@date_3, @date_4))
  
  def service_gap!(animal, span) do 
    Factory.sql_insert!(:service_gap, [animal_id: animal.id, span: span],
      @institution)
  end
end  
