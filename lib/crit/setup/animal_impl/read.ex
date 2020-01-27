defmodule Crit.Setup.AnimalImpl.Read do
  use Crit.Global.Constants
  import Ecto.Query
  alias Crit.Sql
  alias Crit.Setup.Schemas.ServiceGap
  alias Crit.FieldConverters.FromSpan
  import Ecto.Datespan
  import Ecto.Query
  alias Crit.Setup.Schemas.Animal

  defmodule Query do
    import Ecto.Query
    alias Crit.Setup.Schemas.Animal

    def from_all(), do: Ecto.Query.from a in Animal

    def from(where) do
      from a in Animal, where: ^where
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

  def available(species_id, %Date{} = date,
    [ignoring_service_gaps: true,
     ignoring_uses: true], institution) do

    Query.from([species_id: species_id])
    |> where([a], contains_point_fragment(a.span, ^date))
    |> Query.ordered
    |> Sql.all(institution)
  end
  
  def all(institution) do
    Query.from_all
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

  def put_updatable_fields(animals, institution) when is_list(animals) do
    Enum.map(animals, &(put_updatable_fields &1, institution))
  end

  def put_updatable_fields(animal, institution) do
    animal
    |> FromSpan.expand
    |> specific_expansions(institution)
  end

  defp specific_expansions(animal, institution) do
    updatable_service_gaps = 
      Enum.map(animal.service_gaps,
        &(ServiceGap.put_updatable_fields &1, institution))
    %{ animal |
       species_name: animal.species.name, 
       service_gaps: updatable_service_gaps,
       institution: institution
    }
  end
end
