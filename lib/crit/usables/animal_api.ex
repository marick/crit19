defmodule Crit.Usables.AnimalApi do
  use Crit.Global.Constants
  alias Crit.Usables.AnimalImpl.{Read,BulkCreationTransaction,Write}
  alias Crit.Sql
  alias Crit.Usables.HiddenSchemas
  alias Crit.Usables.Schemas.{Animal,BulkAnimal}
  alias Ecto.ChangesetX


  def showable!(id, institution) do
    case Read.one([id: id], institution) do
      nil ->
        raise KeyError, "No animal id #{id}"
      animal ->
        Read.put_virtual_fields(animal)
    end
  end

  def showable_by(field, value, institution) do
    case Read.one([{field, value}], institution) do
      nil ->
        nil
      animal ->
        Read.put_virtual_fields(animal)
    end
  end

  def ids_to_animals(ids, institution) do
    ids
    |> Read.ids_to_animals(institution)
    |> Read.put_virtual_fields
  end

  def all(institution) do
    institution
    |> Read.all
    |> Read.put_virtual_fields
  end

  def form_changeset(animal), do: Animal.form_changeset(animal)

  def update(string_id, attrs, institution) do
    animal = showable!(string_id, institution)
    case Write.update(animal, attrs, institution) do
      {:ok, animal} -> {:ok, animal}
      {:error, changeset} -> {:error, ChangesetX.flush_lock_version(changeset)}
    end
  end

  
  def create_animals(attrs, institution) do
    case BulkCreationTransaction.run(attrs, institution) do
      {:ok, animal_ids} ->
        {:ok, ids_to_animals(animal_ids, institution)}
      {:error, changeset} ->
        {:error, ChangesetX.ensure_forms_display_errors(changeset)}
    end
  end

  def bulk_animal_creation_changeset() do
   %BulkAnimal{
     names: "",
     species_id: 0,
     in_service_datestring: @today,
     out_of_service_datestring: @never,
     timezone: "--to be replaced--"}
     |> BulkAnimal.changeset(%{})
  end

  def available_species(institution) do
    HiddenSchemas.Species.Query.ordered()
    |> Sql.all(institution)
    |> Enum.map(fn %HiddenSchemas.Species{name: name, id: id} -> {name, id} end)
  end

end
