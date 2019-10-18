defmodule Crit.Usables.Animal.Write do
  alias Ecto.ChangesetX
  alias Ecto.Changeset
  alias Crit.Usables.Animal
  alias Crit.Usables.AnimalApi
  alias Crit.Sql

  def update_for_id(string_id, attrs, institution) do
    db_result =
      string_id
      |> String.to_integer
      |> Animal.update_changeset(attrs)
      # |> IO.inspect(label: "insertion changeset")
      |> Sql.update([stale_error_field: :optimistic_lock_error], institution)
    
    case db_result do 
      {:ok, %{id: id}} ->
        {:ok, id}
      {:error, %{errors: [{:optimistic_lock_error, _}]}} ->
        new_changeset = 
          AnimalApi.showable!(String.to_integer(string_id), institution)
          |> Animal.changeset(%{})
          |> Changeset.add_error(:optimistic_lock_error,
                               "Someone else was editing the animal while you were.")
                               |> ChangesetX.ensure_forms_display_errors
        {:error, new_changeset}
      _ -> 
        db_result
    end
  end
end
