defmodule Crit.Usables do
  use Crit.Global.Constants
  alias Crit.Sql
  alias Crit.Usables.Read
  alias Crit.Usables.Write
  alias Crit.Usables.Show
  alias Crit.Ecto.BulkInsert
  alias Crit.Global
  alias Ecto.Changeset
  import Pile.Changeset, only: [ensure_forms_display_errors: 1]

  def get_complete_animal!(id, institution) do
    case Read.Animal.one([id: id], institution) do
      nil ->
        raise KeyError, "No animal id #{id}"
      animal ->
        Show.Animal.convert(animal)
    end
  end

  def get_complete_animal_by_name(name, institution) do
    case Read.Animal.one([name: name], institution) do
      nil ->
        nil
      animal ->
        Show.Animal.convert(animal)
    end
  end

  def ids_to_animals(ids, institution) do
    ids
    |> Read.Animal.ids_to_animals(institution)
    |> Enum.map(&Show.Animal.convert/1)
  end  


  def create_animals(supplied_attrs, institution) do
    attrs = Map.put(supplied_attrs, "timezone", Global.timezone(institution))
    steps = [
      &Write.BulkAnimalWorkflow.validation_step/1,
      &Write.BulkAnimalWorkflow.split_changeset_step/1,
      &Write.BulkAnimalWorkflow.bulk_insert_step/1,
      &bulk_animal__return_value/1,
    ]

    %{attrs: attrs, institution: institution}
    |> run_steps(steps)
    |> extract_result(:animals)
  end

  def run_steps(state, []),
    do: {:ok, state}
  
  def run_steps(state, [next | rest]) do
    case next.(state) do
      {:error, changeset} ->
        {:error, ensure_forms_display_errors(changeset)}
      {:ok, state} ->
        run_steps(state, rest)
    end
  end

  def extract_result({:error, _} = error, _key), do: error
  def extract_result({:ok, state}, key), do: {:ok, state[key]}

  
        

  def bulk_animal__return_value(%{animal_ids: ids, institution: institution} = state) do
    new_state = Map.put(state, :animals, ids_to_animals(ids, institution))
    {:ok, new_state}
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
