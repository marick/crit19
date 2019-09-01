defmodule Crit.Usables.Animal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.{ScheduledUnavailability, Species}

  schema "animals" do
    field :name, :string
    belongs_to :species, Species
    has_many :scheduled_unavailabilities, ScheduledUnavailability

    field :lock_version, :integer, default: 1
    timestamps()
  end

  @doc false
  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name, :species_id, :lock_version])
    |> validate_required([:name, :species_id, :lock_version])
  end
end
