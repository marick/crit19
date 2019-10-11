defmodule Crit.Usables do
  use Crit.Global.Constants
  alias Crit.Sql
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Read
  alias Crit.Usables.Write
  alias Crit.Usables.Show
  import Ecto.ChangesetX, only: [ensure_forms_display_errors: 1]

  def ids_to_animals(ids, institution) do
    ids
    |> Read.Animal.ids_to_animals(institution)
    |> Enum.map(&Show.Animal.convert/1)
  end  

  def create_animals(attrs, institution) do
    case Write.BulkAnimalWorkflow.run(attrs, institution) do
      {:ok, animal_ids} ->
        {:ok, ids_to_animals(animal_ids, institution)}
      {:error, changeset} ->
        {:error, ensure_forms_display_errors(changeset)}
    end
  end

  def update_animal(string_id, attrs, institution) do
    case result = Write.Animal.update_for_id(string_id, attrs, institution) do 
      {:ok, id} -> 
        {:ok, AnimalApi.showable!(id, institution)}
      _ ->
        result
    end
  end

  def bulk_animal_creation_changeset() do
   %Write.BulkAnimal{
     names: "",
     species_id: 0,
     start_date: @today,
     end_date: @never,
     timezone: "--to be replaced--"}
     |> Write.BulkAnimal.changeset(%{})
  end

  def available_species(institution) do
    Read.Species.Query.ordered()
    |> Sql.all(institution)
    |> Enum.map(fn %Read.Species{name: name, id: id} -> {name, id} end)
  end

end
