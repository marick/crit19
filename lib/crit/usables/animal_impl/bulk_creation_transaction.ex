defmodule Crit.Usables.AnimalImpl.BulkCreationTransaction do
  alias Crit.Sql
  import Crit.Sql.Transaction, only: [make_creation_validation_step: 1]
  alias Crit.Usables.Schemas.{Animal,BulkAnimal}
  alias Crit.Ecto.BulkInsert
  alias Crit.Global

  def run(supplied_attrs, institution) do
    attrs = Map.put(supplied_attrs, "timezone", Global.timezone(institution))
    steps = [
      make_creation_validation_step(&BulkAnimal.creation_changeset/1),
      &split_changeset_step/1,
      &bulk_insert_step/1,
    ]

    Sql.Transaction.run_creation(attrs, institution, steps)
  end

  def changeset_to_changesets(%{changes: changes}) do
    base_attrs = %{species_id: changes.species_id,
                   in_service_date: changes.in_service_date,
                   out_of_service_date: changes[:out_of_service_date]
                  }
    
    one_animal = fn name ->
      Animal.from_bulk_creation_changeset(Map.put(base_attrs, :name, name))
    end

    Enum.map(changes.computed_names, one_animal)
  end
  

  defp split_changeset_step(%{original_changeset: changeset} = state) do
    changesets = changeset_to_changesets(changeset)

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
    |> Sql.Transaction.on_error(original_changeset, name: transfer_name_error())
  end
  
  defp transfer_name_error do
    fn failing_changeset, original_changeset ->
      duplicate = failing_changeset.changes.name
      message = ~s[An animal named "#{duplicate}" is already in service]
      Sql.Transaction.transfer_constraint_error(original_changeset, :names, message)
    end
  end
end
