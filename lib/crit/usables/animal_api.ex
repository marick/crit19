defmodule Crit.Usables.AnimalApi do
  use Crit.Global.Constants
  alias Crit.Usables.AnimalImpl.{Read, Write, BulkCreationTransaction}
  alias Crit.Sql
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Hidden
  alias Crit.Usables.Schemas.{Animal,BulkAnimal}
  import Ecto.ChangesetX, only: [ensure_forms_display_errors: 1]

  
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

  def changeset(animal, attrs), do: Animal.changeset(animal, attrs)
  def changeset(fields), do: Animal.changeset(fields)
  
  def update(string_id, attrs, institution) do
    case result = Write.update_for_id(string_id, attrs, institution) do 
      {:ok, id} -> 
        {:ok, showable!(id, institution)}
      _ ->
        result
    end
  end

  def create_animals(attrs, institution) do
    case BulkCreationTransaction.run(attrs, institution) do
      {:ok, animal_ids} ->
        {:ok, AnimalApi.ids_to_animals(animal_ids, institution)}
      {:error, changeset} ->
        {:error, ensure_forms_display_errors(changeset)}
    end
  end

  def bulk_animal_creation_changeset() do
   %BulkAnimal{
     names: "",
     species_id: 0,
     start_date: @today,
     end_date: @never,
     timezone: "--to be replaced--"}
     |> BulkAnimal.changeset(%{})
  end

  def available_species(institution) do
    Hidden.Species.Query.ordered()
    |> Sql.all(institution)
    |> Enum.map(fn %Hidden.Species{name: name, id: id} -> {name, id} end)
  end

end
