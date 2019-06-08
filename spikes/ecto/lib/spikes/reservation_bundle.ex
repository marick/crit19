defmodule Spikes.ReservationBundle do
  use Ecto.Schema

  schema "reservation_bundles" do
    field :name, :string

    many_to_many :animals, Spikes.Animal,
      join_through: "animals__reservation_bundles"

    many_to_many :procedures, Spikes.Procedure,
      join_through: "reservation_bundles__procedures"

    timestamps()
  end
end
