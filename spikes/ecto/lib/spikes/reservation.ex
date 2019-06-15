defmodule Spikes.Reservation do
  use Ecto.Schema

  schema "reservations" do
    has_many :uses, Spikes.Use
    field :interval, Ecto2.Interval
    timestamps()
  end
end
