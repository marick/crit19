defmodule Spikes.ScheduledUnavailability do
  use Ecto.Schema

  schema "scheduled_unavailabilities" do
    has_one :animal, Spikes.Animal
    field :interval, Ecto2.InclusiveDateRange
    field :reason, :string

    timestamps()
  end
end
