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
    "twice per week",
  ]

  def joins(query, procedure_id) do
    from a in query,
      join: p in Procedure, on: p.id == ^procedure_id,
      join: u in Use, on: u.procedure_id == ^procedure_id,
      join: r in Reservation, on: u.reservation_id == r.id
  end

  def describe_result(query) do
    from [a, p, u, r] in query,
      group_by: [a.name, p.name],
      select: %{animal_name: a.name,
                procedure_name: p.name,
                dates: fragment("array_agg(?)", r.date)}
  end

  def where_uses_range(desired_date, days) do
    conflicting_range = date_range(desired_date, days)
    fn query -> 
      where(query, [a, p, u, r], contains_point_fragment(^conflicting_range, r.date))
    end
  end

  def full_query(where_maker, query, procedure_id) do
    joins(query, procedure_id)
    |> where_maker.()
    |> describe_result
  end
  
  def conflicting_uses(query, "once per day", desired_date, procedure_id) do
    where_uses_range(desired_date, 1) |> full_query(query, procedure_id)
  end

  def conflicting_uses(query, "once per week", desired_date, procedure_id) do
    where_uses_range(desired_date, 7) |> full_query(query, procedure_id)
  end

  def conflicting_uses(query, "twice per week", desired_date, procedure_id) do
    where_uses_range(desired_date, 2) |> full_query(query, procedure_id)
  end

  

  defp date_range(date, width) do
    first = Date.add(date, -(width - 1))
    after_last = Date.add(date, width)
    Datespan.customary(first, after_last) |> Datespan.dump!
  end

  def _adjusting_for_end_of_week(desired_date) do
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
