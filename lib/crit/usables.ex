defmodule Crit.Usables do
  alias Crit.Sql
  alias Crit.Usables.{Animal, ServiceGap, AnimalServiceGap, Species}
  alias Crit.Usables.Write.BulkAnimal
  alias Crit.Ecto.BulkInsert
  alias Ecto.Multi
  alias Crit.Ecto.MegaInsert
  alias Crit.Institutions
  alias Ecto.Changeset

  def get_complete_animal!(id, institution) do
    query = 
      Animal.Query.from(id: id) |> Animal.Query.preload_common()
    
    case Sql.one(query, institution) do
      nil ->
        raise KeyError, "No animal id #{id}"
      animal ->
        animal
    end
  end

  def get_complete_animal_by_name(name, institution) do
    Animal.Query.from(name: name)
    |> Animal.Query.preload_common()
    |> Sql.one(institution)
  end

  def create_animals(attrs, institution) do
    result =
      attrs
      |> Map.put("timezone", Institutions.timezone(institution))
      |> BulkAnimal.compute_insertables
      |> Changeset.apply_action(:insert)

    case result do
      {:error, _t} ->
        result
    end
  end


  def create_animal(attrs, institution) do
    attrs
    |> creation_changesets(institution)
    |> creation_continuation(institution)
  end

  defp creation_changesets(attrs, institution) do
    adjusted_attrs = Map.put(attrs, "timezone", Institutions.timezone(institution))
    
    {:ok, animal_changesets} = Animal.creational_changesets(adjusted_attrs)
    {:ok, service_gap_changesets} = ServiceGap.initial_changesets(adjusted_attrs)

    {:ok, [animal_changesets, service_gap_changesets]}
  end


  defp creation_continuation({:error, changeset}, _institution),
    do: {:error, changeset}

    # Note: there's no particular reason for this to be transactional but
  # I wanted to learn more about using Ecto.Multi.
  defp creation_continuation({:ok, [animal_changesets, service_gap_changesets]}, institution) do
    
    animal_opts = [schema: Animal, structs: :animals, ids: :animal_ids]
    service_gap_opts = [schema: ServiceGap, structs: :service_gaps, ids: :service_gap_ids]

    animal_multi =
      MegaInsert.make_insertions(animal_changesets, institution, animal_opts)
      |> MegaInsert.append_collecting(animal_opts)
    service_gap_multi =
      MegaInsert.make_insertions(service_gap_changesets, institution, service_gap_opts)
      |> MegaInsert.append_collecting(service_gap_opts)

    connector_function = fn tx_result ->
      MegaInsert.connection_records(tx_result, AnimalServiceGap, :animal_ids, :service_gap_ids)
      |> MegaInsert.make_insertions(institution, schema: AnimalServiceGap)
    end

    {:ok, tx_result} =
      Multi.new
      |> Multi.append(animal_multi)
      |> Multi.append(service_gap_multi)
      |> Multi.merge(connector_function)
      |> Sql.transaction(institution)

    # When I try to include the final query into the Multi, I get a
    # weird error that I think is some sort of interaction with the
    # `Sql` prefix-handling. That is,
    #        Sql.all(query, "critter4us")
    # fails, but the equivalent
    #        Crit.Repo.all(query, prefix: "demo")
    # works fine.

    animals = ids_to_animals(tx_result.animal_ids, institution)

    {:ok, animals}
    
  end

    
  def bulk_animal_creation_changeset() do
    %BulkAnimal{
      names: "",
      species_id: 0,
      start_date: "today",
      end_date: "never",
      timezone: "--to be replaced--"}
    |> BulkAnimal.changeset(%{})
  end

  

  def animal_creation_changeset(%Animal{} = animal) do
    Animal.changeset(animal, %{})
  end

  def available_species(institution) do
    Species.Query.ordered()
    |> Sql.all(institution)
    |> Enum.map(fn %Species{name: name, id: id} -> {name, id} end)
  end

  def ids_to_animals(ids, institution) do
    query =
      ids
      |> Animal.Query.from_ids
      |> Animal.Query.preload_common
      |> Animal.Query.ordered
    Sql.all(query, institution)
  end
end
