defmodule Crit.Reservations.ReservationImpl.Read do
  alias Crit.Sql
  import Ecto.Query
  alias Crit.Reservations.Schemas.Reservation

  # Someday, figure out how to do a single query that orders the
  # animals and procedure. Note that this isn't actually less efficient
  # than what Ecto produces for this preloading query:
  #
  #    (from r in Reservation, where: [id: ^id])
  #    |> preload([:animals, :procedures])
  #    |> Sql.one(institution)
  #
  #
  # SELECT ... FROM "demo"."reservations" AS r0 WHERE (r0."id" = $1) [26]
  # SELECT ... FROM "demo"."uses" AS u0 WHERE (u0."reservation_id" = $1) 
  # SELECT ... FROM "demo"."animals" AS a0 WHERE (a0."id" = ANY($1)) [[133, 134]]
  # SELECT ... FROM "demo"."procedures" AS p0 WHERE (p0."id" = ANY($1)) [[50, 51]]
  
  def by_id(id, institution) do
    query =
      from r in Reservation, where: r.id == ^id
    
    Sql.one(query, institution)
  end

  def on_dates(inclusive_first, inclusive_last, institution) do
    query = 
      from r in Reservation,
      where: r.date >= ^inclusive_first,
      where: r.date <= ^inclusive_last

    Sql.all(query, institution)
  end

end
