defmodule Crit.Usables.Animal do
  use Ecto.Schema
  import Ecto.Changeset

  schema "animals" do
    field :lock_version, :integer, default: 1
    field :name, :string
    field :species, :string

    timestamps()
  end

  @doc false
  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name, :species, :lock_version])
    |> validate_required([:name, :species, :lock_version])
  end
end
