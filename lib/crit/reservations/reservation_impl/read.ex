defmodule Crit.Reservations.ReservationImpl.Read do
  alias Crit.Sql
  import Ecto.Query
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Reservations.HiddenSchemas.Use
  alias Crit.Setup.Schemas.{Animal, Procedure}
  
  defmodule Query do
    import Ecto.Query
    alias Crit.Reservations.Schemas.Reservation
  
    def from(where), do: from a in Reservation, where: ^where

    def ordered(query) do
      query |> order_by([a], a.name)
    end
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

  def put_updatable_fields(reservation, institution) do 
    uses =
      (from u in Use, where: u.reservation_id == ^reservation.id)
      |> Sql.all(institution)
    
    animal_ids = Enum.map(uses, &(&1.animal_id))
    procedure_ids = Enum.map(uses, &(&1.procedure_id))

    animal_pairs =
      (from a in Animal, where: a.id in ^animal_ids, order_by: a.name)
      |> Sql.all(institution)
      |> EnumX.id_pairs(:name)

    procedure_pairs =
      (from p in Procedure, where: p.id in ^procedure_ids, order_by: p.name)
      |> Sql.all(institution)
      |> EnumX.id_pairs(:name)


    %{reservation |
      animal_pairs: animal_pairs,
      procedure_pairs: procedure_pairs}
  end
end
