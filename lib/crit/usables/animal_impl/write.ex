defmodule Crit.Usables.AnimalImpl.Write do
  alias Ecto.ChangesetX
  alias Ecto.Changeset
  alias Crit.Usables.Schemas.Animal
  alias Crit.Usables.AnimalApi
  alias Crit.Sql

  def update_for_id(string_id, attrs, institution) do
    case update_result(string_id, attrs, institution) do
      {:ok, %Animal{id: id}} ->
        {:ok, id}

      {:error, %{errors: [{:optimistic_lock_error, _}]}} ->
        {:error, changeset_for_lock_error(string_id, institution)}

      result ->
        result
    end
  end

  defp update_result(string_id, attrs, institution) do
    string_id
    |> String.to_integer()
    |> Animal.update_changeset(attrs)
    # |> IO.inspect(label: "insertion changeset")
    |> Sql.update([stale_error_field: :optimistic_lock_error], institution)
  end

  defp changeset_for_lock_error(string_id, institution) do
    AnimalApi.showable!(String.to_integer(string_id), institution)
    |> Animal.changeset(%{})
    |> Changeset.add_error(
      :optimistic_lock_error,
      "Someone else was editing the animal while you were."
    )
    |> ChangesetX.ensure_forms_display_errors()
  end
end
