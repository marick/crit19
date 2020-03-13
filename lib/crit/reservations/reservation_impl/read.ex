defmodule Crit.Reservations.ReservationImpl.Read do
  use Crit.Global.Constants
  import Ecto.Query
  alias Crit.Sql
  import Ecto.Datespan
  alias Crit.Setup.Schemas.{ServiceGap,Animal}
  alias Crit.Reservations.Schemas.Reservation

  defmodule Query do
    import Ecto.Query
    alias Crit.Reservation.Schemas.Reservation

    def available_by_species(date, species_id) do
      from a in Animal,
      where: a.species_id == ^species_id,
      where: a.available == true,
      where: contains_point_fragment(a.span, ^date)
    end

    def subtract(all, remove) do
      from a in all,
        left_join: sa in subquery(remove), on: a.id == sa.id,
        where: is_nil(sa.name)
    end

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


  def rejected_at(:service_gap, %Date{} = date, species_id, institution) do
    Query.available_by_species(date, species_id)
    |> ServiceGap.narrow_animal_query_to_include(date)
    |> Query.ordered
    |> Sql.all(institution)
  end

  def available(date, species_id, institution) do
    all = Query.available_by_species(date, species_id)
    blocked = ServiceGap.narrow_animal_query_to_include(all, date)

    Query.subtract(all, blocked)
    |> Query.ordered
    |> Sql.all(institution)
  end
end
