defmodule Spikes.ScheduledUnavailability do
  use Ecto.Schema

  schema "scheduled_unavailabilities" do
    belongs_to :animal, Spikes.Animal
    field :timespan, Ecto2.Timespan
    field :reason, :string

    timestamps()
  end
end
