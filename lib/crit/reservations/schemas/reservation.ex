defmodule Crit.Reservations.Schemas.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Reservations.HiddenSchemas.Use

  # The date could be extracted from the `span`, but making it explicit
  # is more convenient for some uses.
  
  schema "reservations" do
    field :species_id, :id
    field :date, :date
    field :span, Timespan
    field :timeslot_id, :id
    has_many :uses, Use
    timestamps()
  end

  @required [:span, :date, :species_id, :timeslot_id]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> cast_assoc(:uses)
    |> foreign_key_constraint(:species_id)
  end
end
