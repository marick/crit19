defmodule Spikes.Procedure do
  use Ecto.Schema

  schema "procedures" do
    field :name, :string
    field :species, :string
    many_to_many :reservation_bundles, Spikes.ReservationBundle,
      join_through: "reservation_bundles__procedures"
    has_many :uses, Spikes.Use

    timestamps()
  end
end
