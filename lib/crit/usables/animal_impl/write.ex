defmodule Crit.Usables.AnimalImpl.Write do
  alias Ecto.ChangesetX
  alias Ecto.Changeset
  alias Crit.Usables.Schemas.{Animal, ServiceGap}
  alias Crit.Usables.AnimalApi
  alias Crit.Sql

  def update(animal, attrs, institution) do
    case try_update(animal, attrs, institution) do
      {:error, %{errors: [{:optimistic_lock_error, _}]}} ->
        {:error, changeset_for_lock_error(animal.id, institution)}

      {:error, changeset} ->
        {:error, changeset_for_other_error(changeset)}

      {:ok, result} ->
        {:ok, result}
    end
  end

  defp try_update(animal, attrs, institution) do
    animal
    |> Animal.update_changeset(attrs)
    |> Sql.update([stale_error_field: :optimistic_lock_error], institution)
  end

  defp changeset_for_lock_error(id, institution) do
    AnimalApi.updatable!(id, institution)
    |> Animal.form_changeset
    |> Changeset.add_error(
      :optimistic_lock_error,
      "Someone else was editing the animal while you were."
    )
    |> ChangesetX.ensure_forms_display_errors()
  end

  defp changeset_for_other_error(changeset) do
    with_new_sg =
      [Changeset.change(%ServiceGap{}) | Changeset.get_change(changeset, :service_gaps)]
    
    changeset
    |> ChangesetX.flush_lock_version
    |> Changeset.put_change(:service_gaps, with_new_sg)
    # |> IO.inspect
  end
end
