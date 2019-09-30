defmodule Crit.Usables.Write.Species do
  use Ecto.Schema
  import Ecto.Changeset

  schema "species" do
    field :name, :string
  end

  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
