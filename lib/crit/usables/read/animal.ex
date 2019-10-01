defmodule Crit.Usables.Read.Animal do
  use Ecto.Schema
  alias Crit.Usables.Read.{ServiceGap, Species}
  alias Crit.Ecto.TrimmedString
  import Ecto.Query
  alias Crit.Sql

  schema "animals" do
    field :name, TrimmedString
    field :available, :boolean
    field :lock_version, :integer
    
    belongs_to :species, Species
    many_to_many :service_gaps, ServiceGap, join_through: "animal__service_gap"
    
    timestamps()
  end

  defmodule Query do
    import Ecto.Query
    alias Crit.Usables.Read.Animal

    def all(), do: Ecto.Query.from(Animal)

    def from(where) do
      from Animal, where: ^where
    end

    def from_ids(ids) do
      from a in Animal, where: a.id in ^ids
    end

    def preload_common(query) do
      query |> preload([:service_gaps, :species])
    end

    def ordered(query) do
      query |> order_by([a], a.name)
    end
  end

  def one(where, institution) do
    Query.from(where)
    |> Query.preload_common()
    |> Sql.one(institution)
  end
  
  def all(institution) do
    Query.all
    |> Query.preload_common()
    |> Query.ordered
    |> Sql.all(institution)
  end
  
  def ids_to_animals(ids, institution) do
    ids
    |> Query.from_ids
    |> Query.preload_common
    |> Query.ordered
    |> Sql.all(institution)
  end
end
