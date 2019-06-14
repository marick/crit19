defmodule Spikes.Snippets do

  alias Spikes.{
    Repo,
    Animal,
    Procedure,
    ReservationBundle,
    ScheduledUnavailability
  }

  import Ecto.Query
  import Ecto.Changeset


  # First attempt
  
  def count_overlaps(datetime) do 
    postgres_format = NaiveDateTime.to_string(datetime)

    from a in Animal,
      join: s in assoc(a, :scheduled_unavailabilities),
      where: fragment("? @> ?::timestamp without time zone", s.interval, ^datetime),
      group_by: a.id,
      select: %{id: a.id, name: a.name, count: count(a.id)}
  end

  def available_animals(datetime) do
    from s in subquery(count_overlaps(datetime)),
      right_join: a in Animal, on: a.id == s.id,
      where: is_nil(s.count),
      select: %{id: a.id, name: a.name}
  end

  def available_animals_in_reservation_bundle(datetime, bundle_id) do
    from s in subquery(available_animals(datetime)),
      join: a in "animals__reservation_bundles", on: a.animal_id == s.id,
      distinct: true
  end

  # Second

  def bundle_animal_ids(bundle_id) do
    from arb in "animals__reservation_bundles",
      join: rb in ReservationBundle, on: rb.id == ^bundle_id,
      where: arb.reservation_bundle_id == ^bundle_id,
      select: %{animal_id: arb.animal_id}
  end

  def excluded_animal_ids(datetime) do 
    postgres_format = NaiveDateTime.to_string(datetime)

    from a in Animal,
      join: s in assoc(a, :scheduled_unavailabilities),
      where: fragment("? @> ?::timestamp without time zone", s.interval, ^datetime),
      select: %{animal_id: a.id}
  end
  
  def included_animal_ids(bundle_id, datetime) do
    from a in subquery(bundle_animal_ids(bundle_id)),
      except_all: ^excluded_animal_ids(datetime)
  end
      
  def included_animals(bundle_id, datetime) do
    from a in Animal,
      join: s in subquery(included_animal_ids(bundle_id, datetime)), on: a.id == s.animal_id
  end  

end
