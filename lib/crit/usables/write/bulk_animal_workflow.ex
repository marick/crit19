defmodule Crit.Usables.Write.BulkAnimalWorkflow do
  use Crit.Global.Constants
  alias Crit.Sql
  alias Crit.Usables.Read
  alias Crit.Usables.Write
  alias Crit.Usables.Show
  alias Crit.Ecto.BulkInsert
  alias Crit.Global
  alias Ecto.Changeset
  import Pile.Changeset, only: [ensure_forms_display_errors: 1]

  def validation_step(%{attrs: attrs} = state) do
    changeset = Write.BulkAnimal.compute_insertables(attrs)
    if changeset.valid? do
      {:ok, Map.put(state, :bulk_changeset, changeset)}
    else
      {:error, changeset}
    end
  end

  def split_changeset_step(%{bulk_changeset: changeset} = state) do
    changesets = Write.BulkAnimal.changeset_to_changesets(changeset)

    {:ok, Map.put(state, :changesets, changesets)}
  end

  def bulk_insert_step(%{
        bulk_changeset: changeset,
        changesets: changesets,
        institution: institution} = state) do

    case bulk_insert(changesets, institution) do
      {:ok, %{animal_ids: ids}} ->
        {:ok, Map.put(state, :animal_ids, ids)}
      {:error, single_failure} ->
        duplicate = single_failure.changes.name
        message = ~s|An animal named "#{duplicate}" is already in service|
        changeset
        |> Changeset.add_error(:names, message)
        |> Changeset.apply_action(:insert)
        # Note that `apply_action` will return {:error, changeset} in this case.
    end
  end


#  ---- 


  defp bulk_insert(
    %{animal_changesets: animal_changesets,
      service_gap_changesets: service_gap_changesets},
    institution) do 

    institution
    |> BulkInsert.three_schema_insertion(
           insert: animal_changesets, yielding: :animal_ids,
           insert: service_gap_changesets, yielding: :service_gap_ids,
           many_to_many: Write.AnimalServiceGap)
    |> Sql.transaction(institution)
    |> BulkInsert.simplify_transaction_results(:animal_ids)
  end
    
  
  
end
