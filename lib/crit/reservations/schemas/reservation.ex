defmodule Crit.Reservations.Schemas.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Reservations.HiddenSchemas.Use

  schema "reservations" do
    field :species_id, :id
    field :span, Timespan
#    field :time_slot_id, :id
    

    has_many :uses, Use
#    has_many :animals, through: [:uses 
    timestamps()
  end

  @required [:span, :species_id]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> foreign_key_constraint(:species_id)
  end
end
