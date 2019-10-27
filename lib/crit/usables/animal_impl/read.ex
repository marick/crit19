defmodule Crit.Usables.AnimalImpl.Read do
  use Crit.Global.Constants
  import Ecto.Query
  alias Crit.Sql

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
      query |> preload([:species])
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

  def put_virtual_fields(animals) when is_list(animals) do
    Enum.map(animals, &put_virtual_fields/1)
  end

  def put_virtual_fields(animal) do
    in_service_datestring = Date.to_iso8601(animal.in_service_date)
    out_of_service_datestring = 
      case animal.out_of_service_date do 
        nil -> @never
        date -> Date.to_iso8601(date)
      end
    
    %{ animal |
       species_name: animal.species.name, 
       in_service_datestring: in_service_datestring,
       out_of_service_datestring: out_of_service_datestring
    }
  end
end
