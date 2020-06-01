defmodule Crit.Setup.AnimalApi do
  use Crit.Global.Constants
  import Pile.Interface
  alias Crit.Setup.AnimalImpl.{Read,BulkCreationTransaction,Write}
  alias Crit.Setup.Schemas.{Animal,BulkAnimal}
  alias Ecto.ChangesetX
  use Crit.Sql.CommonSql, schema: Animal

  deftypical(:all_by_species, :all, [species_id: species_id])
  deftypical(:one_by_id, :one, [id: id])
  def_all_by_Xs(:id)
  

  def updatable!(id, institution) do
    case one_by_id(id, institution, preload: Animal.preloads()) do
      nil ->
        raise KeyError, "No animal id #{id}"
      animal ->
        some(Read).put_updatable_fields(animal, institution)
    end
  end

  def ids_to_animals(ids, institution) do
    ids
    |> some(Read).ids_to_animals(institution)
    |> some(Read).put_updatable_fields(institution)
  end

  def all(institution) do
    institution
    |> some(Read).all
    |> some(Read).put_updatable_fields(institution)
  end

  def form_changeset(animal), do: Animal.form_changeset(animal)

  def update(string_id, attrs, institution) do
    string_id
    |> some(__MODULE__).updatable!(institution)
    |> some(Write).update(attrs, institution)
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
     out_of_service_datestring: @never}
     |> BulkAnimal.changeset(%{})
  end

  def query_by_in_service_date(date, species_id),
    do: Read.Query.available_by_species(date, species_id)

  def ids_to_query(ids),
    do: Read.Query.ids_to_query(ids)
end
