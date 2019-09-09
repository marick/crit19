defmodule Crit.Usables.Animal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.{ServiceGap, Species, AnimalServiceGap}
  alias Crit.Ecto.TrimmedString


  schema "animals" do
    field :name, TrimmedString
    belongs_to :species, Species
    field :lock_version, :integer, default: 1
    many_to_many :service_gaps, ServiceGap,
      join_through: AnimalServiceGap

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
        preload: [:service_gaps, :species]
    end
  end
end
