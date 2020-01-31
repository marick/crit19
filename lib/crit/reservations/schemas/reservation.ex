defmodule Crit.Reservations.Schemas.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Sql
  alias Crit.Reservations.HiddenSchemas.Use

  schema "reservations" do
    field :span, Timespan
    field :species_id, :id

    has_many :uses, Use
    timestamps()
  end

  @required [:span, :species_id]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> foreign_key_constraint(:species_id)
  end

  def create(superset, institution) do
    uses =
      Use.unsaved_uses(superset.chosen_animal_ids, superset.chosen_procedure_ids)

    reservation = %__MODULE__{
      span: superset.span,
      species_id: superset.species_id,
      uses: uses
    }

    Sql.insert(reservation, institution)
  end
end
