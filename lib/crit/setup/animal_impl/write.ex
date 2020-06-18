defmodule Crit.Setup.AnimalImpl.Write do
  alias Ecto.ChangesetX
  alias Ecto.Changeset
  alias Crit.Setup.Schemas.{AnimalOld, ServiceGapOld}
  alias Crit.Setup.AnimalApi
  alias Crit.Sql

  def update(animal, attrs, institution) do
    case try_update(animal, attrs, institution) do
      {:error, %{errors: [{:optimistic_lock_error, _}]}} ->
        {:error, changeset_for_lock_error(animal.id, institution)}

      {:error, partial_changeset} ->
        changeset =
          partial_changeset
          |> ChangesetX.flush_lock_version
          |> changeset_for_other_error
        {:error, changeset}
      {:ok, result} ->
        {:ok, result}
    end
  end

  defp try_update(animal, attrs, institution) do
    animal
    |> AnimalOld.update_changeset(attrs)
    |> Sql.update([stale_error_field: :optimistic_lock_error], institution)
  end

  defp changeset_for_lock_error(id, institution) do
    AnimalApi.updatable!(id, institution)
    |> AnimalOld.form_changeset
    |> Changeset.add_error(
      :optimistic_lock_error,
      "Someone else was editing the animal while you were."
    )
    |> ChangesetX.ensure_forms_display_errors()
  end

  defp changeset_for_other_error(changeset) do
    case Changeset.fetch_change(changeset, :service_gaps) do
      {:ok, [ %{action: :insert} | _rest ]} = _has_bad_new_service_gap ->
        changeset

      {:ok, only_has_service_gap_updates} ->
        Changeset.put_change(changeset, :service_gaps,
          [Changeset.change(%ServiceGapOld{}) | only_has_service_gap_updates])

      :error -> 
        %{changeset | data: AnimalOld.prepend_empty_service_gap(changeset.data)}
    end
  end
end
