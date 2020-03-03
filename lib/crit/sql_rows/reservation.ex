defmodule Crit.SqlRows.Reservation do 
  use Crit.Global.Constants
  import Ecto.Query
  alias Crit.Sql
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Reservations.HiddenSchemas.Use
  alias Crit.Setup.Schemas.{Animal, Procedure}
  import Ecto.Timespan


  def timespan_uses(timespan, institution) do
    {:ok, ps_range} = dump(timespan)
    
    query = 
      from r in Reservation,
      join: a in Animal, as: :animal,
      join: u in Use,
      join: p in Procedure, as: :procedure,
      where: overlaps_fragment(r.span, ^ps_range),
      where: u.reservation_id == r.id,
      where: u.procedure_id == p.id,
      where: u.animal_id == a.id

    query =
      from [animal: a, procedure: p] in query,
      group_by: [a.id, p.id],
      select: %{animal_name: a.name, animal_id: a.id,
                procedure_name: p.name, procedure_id: p.id,
                count: count(p.id)},
      order_by: [a.name, p.name]
    

    Sql.all(query, institution)
  end

end
