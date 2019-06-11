defmodule Spikes.Animal do
  use Ecto.Schema

  schema "animals" do
    field :name, :string
    field :species, :string
    many_to_many :reservation_bundles, Spikes.ReservationBundle,
      join_through: "animals__reservation_bundles"
    has_many :scheduled_unavailabilities, Spikes.ScheduledUnavailability
    
    timestamps()
  end
end
