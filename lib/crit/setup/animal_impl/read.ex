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

    def start(), do: from a in Animal

    def start(where) do
      from a in Animal, where: ^where
    end

    def from_ids(ids) do
      from a in Animal, where: a.id in ^ids
    end

    def preload_common(query) do
      query |> preload([:species, :service_gaps])
    end

    def available_by_species(date, species_id) do
      from a in Animal,
      where: a.species_id == ^species_id,
      where: a.available == true,
      where: contains_point_fragment(a.span, ^date)
    end

    def subtract(all, remove) do
      from a in all,
        left_join: sa in subquery(remove), on: a.id == sa.id,
        where: is_nil(sa.name)
    end

    def ordered(query) do
      query |> order_by([a], a.name)
    end
  end

  def one(where, institution) do
    Query.start(where)
    |> Query.preload_common()
    |> Sql.one(institution)
  end

  def all(institution) do
    Query.start
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


  def rejected_at(:service_gap, %Date{} = date, species_id, institution) do
    Query.available_by_species(date, species_id)
    |> ServiceGap.narrow_animal_query_to_include(date)
    |> Query.ordered
    |> Sql.all(institution)
  end

  def available(date, species_id, institution) do
    all = Query.available_by_species(date, species_id)
    blocked = ServiceGap.narrow_animal_query_to_include(all, date)

    Query.subtract(all, blocked)
    |> Query.ordered
    |> Sql.all(institution)
  end

end
