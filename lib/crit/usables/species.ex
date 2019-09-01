defmodule Crit.Usables.Species do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.Animal

  schema "species" do
    field :name, :string
    has_many :animals, Animal
  end

  @doc false
  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
