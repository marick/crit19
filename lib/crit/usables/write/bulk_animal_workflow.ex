defmodule Crit.Usables.Write.BulkAnimalWorkflow do
  alias Crit.Sql
  alias Crit.Usables.Write
  alias Crit.Usables.Hidden
  alias Crit.Ecto.BulkInsert
  alias Crit.Global

  def run(supplied_attrs, institution) do
    attrs = Map.put(supplied_attrs, "timezone", Global.timezone(institution))
    steps = [
      &validation_step/1,
      &split_changeset_step/1,
      &bulk_insert_step/1,
    ]

    Sql.Transaction.run(attrs, institution, steps)
  end

  # The essential steps in the workflow

  defp validation_step(state) do
    Sql.Transaction.validation_step(
      state,
      &Write.BulkAnimal.compute_insertables/1)
  end

  defp split_changeset_step(%{original_changeset: changeset} = state) do
    changesets = Write.BulkAnimal.changeset_to_changesets(changeset)

    {:ok, Map.put(state, :changesets, changesets)}
  end

  defp bulk_insert_step(%{
        original_changeset: original_changeset,
        changesets: changesets,
        institution: institution}) do

    %{animal_changesets: animal_changesets,
      service_gap_changesets: service_gap_changesets} = changesets

    script = 
      institution
      |> BulkInsert.three_schema_insertion(
           insert: animal_changesets, yielding: :animal_ids,
           insert: service_gap_changesets, yielding: :service_gap_ids,
           many_to_many: Hidden.AnimalServiceGap)

    script
    |> Sql.transaction(institution)
    |> Sql.Transaction.on_ok(extract: :animal_ids)
    |> Sql.Transaction.on_failed_step(transfer_error_to(original_changeset))
  end

  # This is dodgy. We happen to know that the only kind of changeset error
  # that can happen in a transaction is because of a duplicate animal.
  defp transfer_error_to(original_changeset) do
    fn _, failing_changeset ->
      duplicate = failing_changeset.changes.name
      message = ~s[An animal named "#{duplicate}" is already in service]
      {:error,
       Sql.Transaction.transfer_constraint_error(original_changeset, :names, message)
      }
    end
  end
end
