defmodule Crit.Usables.Animal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.{ScheduledUnavailability, Species}
  alias Crit.Ecto.TrimmedString


  schema "animals" do
    field :name, TrimmedString
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


  defmodule Query do
    import Ecto.Query
    alias Crit.Usables.Animal

    def complete(id) do
      from a in Animal,
        where: a.id == ^id,
        preload: [:scheduled_unavailabilities, :species]
    end
  end
end
