defmodule Crit.Reservations.RestPeriod do
  import Ecto.Query
#  alias Crit.Sql.CommonQuery
  alias Crit.Setup.Schemas.Procedure
  alias Crit.Reservations.HiddenSchemas.Use
  alias Crit.Reservations.Schemas.Reservation
  alias Ecto.Datespan
  import Ecto.Datespan  # This has to be imported for query construction.
  
 
  def possible_frequencies, do: [
    "unlimited",
    "once per day",
    "once per week",
  ]

  def conflicting_uses(query, conflicting_range, procedure_id) do
    from a in query,
      join: p in Procedure, on: p.id == ^procedure_id,
      join: u in Use, on: u.procedure_id == ^procedure_id,
      join: r in Reservation, on: u.reservation_id == r.id,
      where: contains_point_fragment(^conflicting_range, r.date),
      select: %{animal_name: a.name, procedure_name: p.name, date: r.date}
  end
  
  def conflicting_uses(query, "once per day", desired_date, procedure_id) do
    range = date_range(desired_date, 1)
    conflicting_uses(query, range, procedure_id)
  end

  def conflicting_uses(query, "once per week", desired_date, procedure_id) do
    range = date_range_with_week_boundary(desired_date)
    conflicting_uses(query, range, procedure_id)
  end

  defp date_range(date, width) do
    first = Date.add(date, -(width - 1))
    after_last = Date.add(date, width)
    Datespan.customary(first, after_last) |> Datespan.dump!
  end

  defp date_range_with_week_boundary(desired_date) do
    case Calendar.Date.day_of_week_name(desired_date) do
      "Sunday" ->
        date_range(desired_date, 2)
      "Monday" -> 
        desired_date |> Date.add(-1) |> date_range(2)
      _ -> 
        date_range(desired_date, 1)
    end
  end
end
