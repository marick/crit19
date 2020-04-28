defmodule Crit.Reservations.RestPeriod do
  import Ecto.Query
#  alias Crit.Sql.CommonQuery
  alias Crit.Setup.Schemas.{Animal, Procedure}
  alias Crit.Reservations.HiddenSchemas.Use
  alias Crit.Reservations.Schemas.Reservation
  alias Ecto.Datespan
  import Ecto.Datespan  # This has to be imported for query construction.
  
 
  def possible_frequencies, do: [
    "unlimited",
    "once per day",
    "twice a week",
    "every two weeks",
    "every 21 days",
    "once a month",
    "every two months",
  ]
  
  def conflicting_uses(query, "once per day", desired_date, procedure_id) do
    conflicting_range = date_range(desired_date, 1)
    
    from a in query,
      join: p in Procedure, on: p.id == ^procedure_id,
      join: u in Use, on: u.procedure_id == ^procedure_id,
      join: r in Reservation, on: u.reservation_id == r.id,
      where: contains_point_fragment(^conflicting_range, r.date),
      select: %{animal_name: a.name, procedure_name: p.name, date: r.date}
  end

  defp date_range(date, width) do
    first = Date.add(date, -(width - 1))
    after_last = Date.add(date, width)
    Datespan.customary(first, after_last) |> Datespan.dump!
  end
    
    
end
