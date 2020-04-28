defmodule Crit.Reservations.RestPeriodTest do
  use Crit.DataCase
  alias Crit.Reservations.RestPeriod
  alias Crit.Exemplars.{ReservationFocused,Available}
  alias Crit.Sql
  alias Crit.Setup.Schemas.{Animal, Procedure}

  setup do
    frequency = Factory.sql_insert!(:procedure_frequency, calculation_name: "name")
    procedure = Factory.sql_insert!(:procedure, species_id: @bovine_id, frequency_id: frequency.id)
    bossie = Available.bovine("bossie")
    unused = Available.bovine("unused")
    reservation = ReservationFocused.reserved!(@bovine_id,
      [bossie.name], [procedure.name], date: @date_2) |> IO.inspect
    [procedure: procedure, bossie: bossie, reservation: reservation]
  end

  test "foo", %{procedure: procedure, bossie: bossie, reservation: reservation} do 
    new_date = Date.add(@date_2, 1)
    animal_ids = [bossie.id]

    query =
      from a in Animal, where: a.id in ^animal_ids
    


    [actual] = 
      RestPeriod.conflicting_uses(query, "once per day", reservation.date, procedure.id)
      |> IO.inspect
      |> Sql.all(@institution)

    assert_fields(actual,
      animal_name: "bossie",
      procedure_name: procedure.name,
      date: @date_2)
  end



end
