defmodule Crit.Setup.Schemas.Species do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.TrimmedString

  schema "species" do
    field :name, TrimmedString
  end

  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name])
    |> validate_required([:name])
  end
end
