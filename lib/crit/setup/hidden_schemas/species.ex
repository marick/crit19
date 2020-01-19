defmodule Crit.Setup.HiddenSchemas.Species do
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

  defmodule Query do
    import Ecto.Query
    alias Crit.Setup.HiddenSchemas.Species

    def ordered() do
      from s in Species, order_by: s.name
    end
  end
  
end
