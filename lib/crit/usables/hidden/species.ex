defmodule Crit.Usables.Hidden.Species do
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

  defmodule Query do
    import Ecto.Query
    alias Crit.Usables.Hidden.Species

    def ordered() do
      from s in Species, order_by: s.name
    end
  end
  
end
