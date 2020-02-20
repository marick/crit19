defmodule Crit.Reservations.ReservationImpl.Read do
  alias Crit.Sql
  alias Crit.Reservations.HiddenSchemas.Use
  
  defmodule Query do
    import Ecto.Query
    alias Crit.Reservations.Schemas.Reservation
  
    def from(where), do: from r in Reservation, where: ^where
  end

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
    Query.from(id: id)
    |> Sql.one(institution)
  end

  def by(where, institution) do
    Query.from(where)
    |> Sql.all(institution)
  end

  def put_updatable_fields(reservation, institution) do 
    {animals, procedures} = Use.all_used(reservation.id, institution)

    %{reservation |
      animal_pairs: EnumX.id_pairs(animals, :name),
      procedure_pairs: EnumX.id_pairs(procedures, :name)}
  end
end
