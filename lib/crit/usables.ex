defmodule Crit.Usables do
  use Crit.Global.Constants
  alias Crit.Sql
  alias Crit.Usables.AnimalApi
  alias Crit.Usables.Hidden
  alias Crit.Usables.Write
  import Ecto.ChangesetX, only: [ensure_forms_display_errors: 1]

  def create_animals(attrs, institution) do
    case Write.BulkAnimalWorkflow.run(attrs, institution) do
      {:ok, animal_ids} ->
        {:ok, AnimalApi.ids_to_animals(animal_ids, institution)}
      {:error, changeset} ->
        {:error, ensure_forms_display_errors(changeset)}
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
    Hidden.Species.Query.ordered()
    |> Sql.all(institution)
    |> Enum.map(fn %Hidden.Species{name: name, id: id} -> {name, id} end)
  end

end
