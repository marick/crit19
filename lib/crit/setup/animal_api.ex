defmodule Crit.Setup.AnimalApi do
  use Crit.Global.Constants
  import Pile.Interface
  alias Crit.Setup.AnimalImpl.{Read,BulkCreationTransaction}
  alias CritBiz.ViewModels.Setup.BulkAnimal
  alias Crit.Setup.Schemas.AnimalOld
  alias Ecto.ChangesetX
  use Crit.Sql.CommonSql, schema: AnimalOld

  def ids_to_animals(ids, institution) do
    ids
    |> some(Read).ids_to_animals(institution)
    |> some(Read).put_updatable_fields(institution)
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
