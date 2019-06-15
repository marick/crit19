defmodule Spikes.Snippets do

  alias Spikes.{
    Repo,
    Animal,
    Procedure,
    Reservation,
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

  def excluded_animal_ids(desired_interval) do
    {:ok, as_range} = Ecto2.Interval.dump desired_interval
    from a in Animal,
      join: s in assoc(a, :scheduled_unavailabilities),
      where: fragment("? && ?::tsrange", s.interval, ^as_range),
      select: %{animal_id: a.id}
  end
  
  def included_animal_ids(bundle_id, desired_interval) do
    from a in subquery(bundle_animal_ids(bundle_id)),
      except_all: ^excluded_animal_ids(desired_interval)
  end
      
  def included_animals(bundle_id, desired_interval) do
    from a in Animal,
      join: s in subquery(included_animal_ids(bundle_id, desired_interval)),
      on: a.id == s.animal_id
  end

  # reservation_period(~D[2001-01-01], 4, 1)
  def reservation_period(date, ordinal_hour, ordinal_duration) do
    {:ok, first_time} = Time.new(ordinal_hour, 0, 0, 0)
    {:ok, first_naive} = NaiveDateTime.new(date, first_time)
    last_naive = NaiveDateTime.add(first_naive, ordinal_duration * 60 * 60)
    
    Ecto2.Interval.interval(first_naive, last_naive)
  end



  # reservations on a particular date
  def reservations_on_date(date) do
    {:ok, day} = reservation_period(date, 0, 24) |> Ecto2.Interval.dump
    from r in Reservation,
      where: fragment("? && ?::tsrange", r.interval, ^day)
  end

  def reservation_animals(%Reservation{} = reservation),
    do: reservation_animals(reservation.id)

  def reservation_animals(reservation_id) do
    from a in Animal,
      join: u in Spikes.Use, on: a.id == u.animal_id,
      where: u.reservation_id == ^reservation_id
  end
end
