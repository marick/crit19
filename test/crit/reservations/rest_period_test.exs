defmodule Crit.Reservations.RestPeriodTest do
  use Crit.DataCase
  alias Crit.Reservations.RestPeriod
  alias Crit.Exemplars.{ReservationFocused,Available}
  alias Crit.Sql
  alias Crit.Setup.Schemas.{Animal}

  def procedure_with_frequency(calculation_name) do
    frequency =
      Factory.sql_insert!(:procedure_frequency,
        name: calculation_name <> " frequency procedure",
        calculation_name: calculation_name)
    Factory.sql_insert!(:procedure,
      species_id: @bovine_id,
      frequency_id: frequency.id)
  end

  def existing_reservation do
    procedure = procedure_with_frequency("not used yet")
    bossie = Available.bovine("bossie")
    reservation = ReservationFocused.reserved!(@bovine_id,
      [bossie.name], [procedure.name], date: @date_2)
    [procedure: procedure, bossie: bossie, reservation: reservation]
  end    

  setup do
    existing_reservation()
  end

  test "foo", %{procedure: procedure, bossie: bossie, reservation: reservation} do
    Available.bovine("unused")

    animal_ids = [bossie.id]

    query =
      from a in Animal, where: a.id in ^animal_ids

    [actual] = 
      RestPeriod.conflicting_uses(query, "once per day", reservation.date, procedure.id)
      |> Sql.all(@institution)

    assert_fields(actual,
      animal_name: "bossie",
      procedure_name: procedure.name,
      date: @date_2)
  end



end
