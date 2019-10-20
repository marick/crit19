defmodule Crit.Usables.Animal.BulkCreationTransaction do
  alias Crit.Sql
  import Crit.Sql.Transaction, only: [make_validation_step: 1]
  alias Crit.Usables.Animal
  alias Crit.Usables.Schemas.BulkAnimal
  alias Crit.Ecto.BulkInsert
  alias Crit.Global

  def run(supplied_attrs, institution) do
    attrs = Map.put(supplied_attrs, "timezone", Global.timezone(institution))
    steps = [
      make_validation_step(&BulkAnimal.compute_insertables/1),
      &split_changeset_step/1,
      &bulk_insert_step/1,
    ]

    Sql.Transaction.run(attrs, institution, steps)
  end

  defp split_changeset_step(%{original_changeset: changeset} = state) do
    changesets = BulkAnimal.changeset_to_changesets(changeset)

    {:ok, Map.put(state, :changesets, changesets)}
  end

  defp bulk_insert_step(%{
        original_changeset: original_changeset,
        changesets: changesets,
        institution: institution}) do

    changesets
    |> BulkInsert.idlist_script(institution, schema: Animal, ids: :animal_ids)
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
