defmodule Crit.Usables.Read.Species do
  use Ecto.Schema

  schema "species" do
    field :name, :string
  end

  defmodule Query do
    import Ecto.Query

    def ordered() do
      from s in "species", order_by: s.name
    end
  end
end
