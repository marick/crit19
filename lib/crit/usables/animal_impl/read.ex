defmodule Crit.Usables.AnimalImpl.Read do
  use Crit.Global.Constants
  import Ecto.Query
  alias Crit.Sql
  alias Crit.Usables.Schemas.ServiceGap
  alias Crit.FieldConverters.FromSpan

  defmodule Query do
    import Ecto.Query
    alias Crit.Usables.Schemas.Animal

    def all(), do: Ecto.Query.from(Animal)

    def from(where) do
      from Animal, where: ^where
    end

    def from_ids(ids) do
      from a in Animal, where: a.id in ^ids
    end

    def preload_common(query) do
      query |> preload([:species, :service_gaps])
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

  def put_updatable_fields(animals) when is_list(animals) do
    Enum.map(animals, &put_updatable_fields/1)
  end

  def put_updatable_fields(animal) do
    animal
    |> FromSpan.expand
    |> specific_expansions
  end

  defp specific_expansions(animal) do
    %{ animal |
       species_name: animal.species.name, 
       service_gaps: Enum.map(animal.service_gaps, &ServiceGap.put_updatable_fields/1)
    }
  end
end
