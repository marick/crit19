defmodule Crit.Reports.AnimalReports do 
  use Crit.Global.Constants
  import Ecto.Query
  alias Crit.Sql
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Reservations.HiddenSchemas.Use
  alias Crit.Setup.Schemas.{Animal, Procedure}
  import Ecto.Timespan


  def use_rows(first_date, last_date, institution) do
    range = range(first_date, last_date)
    
    query = 
      from a in Animal,
      join: r in Reservation,
      join: u in Use,
      join: p in Procedure,
      where: overlaps_fragment(r.span, ^range),
      where: u.reservation_id == r.id,
      where: u.procedure_id == p.id,
      where: u.animal_id == a.id,
      group_by: [a.id, p.id],
      select: %{animal_name: a.name, procedure_name: p.name, count: count(p.id)},
      order_by: [a.name, p.name]
    

    Sql.all(query, institution)
  end

  defp range(%Date{} = first_date, %Date{} = last_date) do 
    {:ok, range} =
      customary(first_date, Date.add(last_date, 1))
      |> dump
    range
  end
end
