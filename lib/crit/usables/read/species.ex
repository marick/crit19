defmodule Crit.Usables.Read.Species do
  use Ecto.Schema

  schema "species" do
    field :name, :string
  end

  defmodule Query do
    import Ecto.Query
    alias Crit.Usables.Read.Species    

    def ordered() do
      from s in Species, order_by: s.name
    end
  end
end
