defmodule Spikes.Animal do
  use Ecto.Schema

  schema "animals" do
    field :name, :string
    field :species, :string
    field :unavailable, Ecto2.InclusiveDateRange
    many_to_many :reservation_bundles, Spikes.ReservationBundle,
      join_through: "animals__reservation_bundles"

    timestamps()
  end
end
