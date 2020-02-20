defmodule Crit.Reservations.Schemas.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Reservations.HiddenSchemas.Use

  schema "reservations" do
    field :species_id, :id
    field :span, Timespan
    field :timeslot_id, :id
    has_many :uses, Use

    field :animal_pairs, :any, virtual: true
    field :procedure_pairs, :any, virtual: true
    timestamps()
  end

  @required [:span, :species_id, :timeslot_id]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_assoc(:uses)
    |> foreign_key_constraint(:species_id)
  end
end
