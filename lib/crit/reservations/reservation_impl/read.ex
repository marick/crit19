defmodule Crit.Reservations.ReservationImpl.Read do
  use Crit.Global.Constants
  import Ecto.Query
  alias Crit.Sql
  alias Crit.Sql.CommonQuery
  alias Crit.Setup.AnimalApiOld
  alias Crit.Setup.Schemas.ServiceGap
  alias Crit.Reservations.Schemas.{Reservation,Use}

  defmodule Query do
    import Ecto.Query
    alias Crit.Reservations.Schemas.Reservation

    def rejected_at(:service_gap, desired) do
      AnimalApiOld.query_by_in_service_date(desired.date, desired.species_id)
      |> ServiceGap.narrow_animal_query_by(desired.date)
      |> CommonQuery.ordered_by_name
    end
    
    def rejected_at(:uses, desired) do
      AnimalApiOld.query_by_in_service_date(desired.date, desired.species_id)
      |> Use.narrow_animal_query_by(desired.span)
      |> CommonQuery.ordered_by_name
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

  def in_service(desired, institution) do
    AnimalApiOld.query_by_in_service_date(desired.date, desired.species_id)
    |> CommonQuery.ordered_by_name
    |> Sql.all(institution)
  end
  
  @doc """
  Produces an animal that can be reserved before the fact:
  in service, not in a service gap, and not already reserved for the desired time.
  (Later, it will not be in a procedure-exclusion range.)
  """
  def before_the_fact_animals(%{species_id: species_id, date: date, span: span},
    institution) do
    
    base_query = AnimalApiOld.query_by_in_service_date(date, species_id)

    reducer = fn make_restriction_query, query_so_far ->
      CommonQuery.subtract(query_so_far, make_restriction_query.(query_so_far))
    end
    
    date_blocker = &(ServiceGap.narrow_animal_query_by(&1, date))
    timespan_blocker = &(Use.narrow_animal_query_by(&1, span))

    [date_blocker, timespan_blocker]
    |> Enum.reduce(base_query, reducer)
    |> CommonQuery.ordered_by_name
    |> Sql.all(institution)
  end
end
