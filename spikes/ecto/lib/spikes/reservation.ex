defmodule Spikes.Reservation do
  use Ecto.Schema

  schema "reservations" do
    has_many :uses, Spikes.Use
    field :timespan, Ecto2.Timespan
    timestamps()
  end
end
