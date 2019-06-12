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

  def count_overlaps(datetime) do
    postgres_format = NaiveDateTime.to_string(datetime)
    
    q = from a in Animal,
      join: s in assoc(a, :scheduled_unavailabilities),
      where: fragment("? @> ?::timestamp without time zone", s.interval, ^datetime),
      group_by: a.id,
      select: %{id: a.id, name: a.name, count: count(a.id)}
  end

end
