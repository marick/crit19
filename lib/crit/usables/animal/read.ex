defmodule Crit.Usables.Animal.Read do
  use Crit.Global.Constants
  alias Ecto.Datespan
  import Ecto.Query
  alias Crit.Sql

  defmodule Query do
    import Ecto.Query
    alias Crit.Usables.Write.Animal

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

  def put_virtual_fields(animal) do
    timespans = Enum.map(animal.service_gaps, &(&1.gap))

    in_service_date =
      timespans
      |> Enum.find(&Datespan.infinite_down?/1)

    in_service_iso = Date.to_iso8601(in_service_date.last)

    out_of_service_iso = 
      case Enum.find(timespans, &Datespan.infinite_up?/1) do
        nil -> @never
        date -> Date.to_iso8601(date.first)
      end
    
    %{ animal |
       species_name: animal.species.name, 
       in_service_date: in_service_iso,
       out_of_service_date: out_of_service_iso
    }

    
  end
end
