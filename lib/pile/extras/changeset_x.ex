defmodule Ecto.ChangesetX do
  alias Ecto.Changeset
  use Crit.Types

  # Phoenix `form_for` only displays errors when the `action` field
  # is non-nil.
  def represents_form_errors?(changeset), do: changeset.action

  # If you manually add an error to a changeset, that error won't be
  # displayed unless you also remember to set the action to non-nil
  @spec ensure_forms_display_errors(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def ensure_forms_display_errors(changeset) do
    {:error, new_changeset} =
      Changeset.apply_action(changeset, :insert)
    new_changeset
  end

  @spec flush_lock_version(Ecto.Changeset.t()) :: Ecto.Changeset.t()
  def flush_lock_version(changeset),
    do: Ecto.Changeset.delete_change(changeset, :lock_version)

  def has_changes_for?(changeset, field), do: Map.has_key?(changeset.changes, field)
  def has_data_for?(changeset, field), do: Map.has_key?(changeset.data, field)

  def has_field?(changeset, field) do
    has_changes_for?(changeset, field) || has_data_for?(changeset, field)
  end

  def current_value(changeset, field) do
    cond do
      has_changes_for?(changeset, field) -> Map.get(changeset.changes, field)
      has_data_for?(changeset, field) -> Map.get(changeset.data, field)
      true -> raise "no value to retrieve"
    end
  end

  def values(changeset, keys), 
    do: Enum.map(keys, &(Changeset.get_field(changeset, &1)))

  def empty_text_field?(changeset, field) do
    value = current_value(changeset, field)
    value == nil || value == ""
  end

  # Hiding textual values out of an excess of caution

  @hidden_string "--hidden--"

  def hide(changeset, fields) when is_list(fields) do
    Enum.reduce(fields, changeset, &hide(&2, &1))
  end

  def hide(changeset, field),
    do: put_in(changeset, path_to(field), @hidden_string)

  def hidden?(changeset, field) do
    has_changes_for?(changeset, field) == false &&
      get_in(changeset, path_to(field)) == @hidden_string
  end

  def fetch_original!(changeset, field) do
    source = changeset.data
    if Map.has_key?(source, field) do 
      Map.get(source, field)
    else
      raise KeyError, "key #{inspect field} not found in: #{inspect source}"
    end
  end

  defp path_to(field), do: [Access.key(:data), Access.key(field)]

  def all_valid?(list), do: Enum.all?(list, &(&1.valid?))
  def all_valid?(top, list), do: top.valid? && all_valid?(list)

  @spec ids_to_delete_from(Changeset.t, :atom) :: MapSet.t(db_id())
  def ids_to_delete_from(container, list_field) do
      container
      |> Changeset.fetch_field!(list_field)
      |> Enum.filter(&(Changeset.get_change(&1, :delete, false)))
      |> Enum.map(&Changeset.get_field(&1, :id))
      |> MapSet.new
  end

  # Note: the `to` field may be a changeset that doesn't
  # show errors (has a `nil` action). `Changeset.add_error` automatically
  # makes the changeset invalid, but we explicitly force it to
  # display an error.
  def merge_only_errors(to, from) do
    from.errors
    |> Enum.reduce(to, fn {field, {message, keyword_list}}, acc ->
         Changeset.add_error(acc, field, message, keyword_list)
       end)
    |> ensure_forms_display_errors
  end
end
