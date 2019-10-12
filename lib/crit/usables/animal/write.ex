defmodule Crit.Usables.Animal.Write do
  alias Crit.Usables.Animal.Changeset
  alias Crit.Sql

  def update_for_id(string_id, attrs, institution) do
    db_result =
      string_id
      |> Changeset.update_changeset(attrs)
      |> Sql.update([stale_error_field: :optimistic_lock_error], institution)

    case db_result do 
      {:ok, %{id: id}} ->
        {:ok, id}
      _ -> 
        db_result
    end
  end
end
