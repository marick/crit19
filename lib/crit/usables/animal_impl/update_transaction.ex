defmodule Crit.Usables.AnimalImpl.UpdateTransaction do
  alias Crit.Sql
  import Crit.Sql.Transaction, only: [make_update_validation_step: 1]
  alias Crit.Usables.Schemas.{Animal}
  alias Ecto.Multi
  alias Ecto.Changeset
  alias Ecto.ChangesetX
  alias Crit.Usables.AnimalApi


  def run(animal, supplied_attrs, institution) do
    steps = [
      make_update_validation_step(&Animal.update_changeset__2/2),
      &split_changeset_step/1,
      &transaction_step/1,
    ]

    state = %Sql.Transaction.State{
      current_struct: animal,
      attrs: supplied_attrs,
      institution: institution
    }
    Sql.Transaction.run_steps(state, steps)
  end

  defp split_changeset_step(%{original_changeset: _changeset} = state) do
    {:ok, state}
  end

  defp transaction_step(%{
        original_changeset: animal_changeset,
        # changesets: changesets,
        institution: institution}) do

    script =
      Multi.update(Multi.new, :animal_part, animal_changeset, Sql.multi_opts(institution, stale_error_field: :optimistic_lock_error))
    
    result = Sql.transaction(script, institution)
    case result do
      {:ok, tx_result} ->
        {:ok, tx_result[:animal_part].id}
      {:error, :animal_part, failing_changeset, _so_far} -> 
        {:error, animal_part_problem(animal_changeset, failing_changeset, institution)}
    end
  end


  def animal_part_problem(animal_changeset, failing_changeset, institution) do 
    case failing_changeset.errors do
      [{:name, _}] ->
        failing_changeset
      [{:optimistic_lock_error, _}] ->
          changeset_for_lock_error(animal_changeset.data.id, institution)
    end
  end

  defp changeset_for_lock_error(id, institution) do
    AnimalApi.showable!(id, institution)
    |> Animal.changeset(%{})
    |> Changeset.add_error(
      :optimistic_lock_error,
      "Someone else was editing the animal while you were."
    )
    |> ChangesetX.ensure_forms_display_errors()
  end
end
