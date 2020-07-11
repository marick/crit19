defmodule Ecto.ChangesetX do
  use ExContract
  alias Ecto.Changeset
  use Crit.Types

  # --------Fields and changes  ---------------------------------------------

  def newest!(cs, keys) when is_list(keys), do: Enum.map(keys, &(newest!(cs, &1)))
  def newest!(cs, field), do: Changeset.fetch_field!(cs, field)

  def new!(cs, field), do: Changeset.fetch_change!(cs, field)
  def old!(cs, field), do: Map.fetch!(cs.data, field)

  
  # --------Errors ---------------------------------------------

  # Phoenix `form_for` only displays errors when the `action` field
  # is non-nil.
  def represents_form_errors?(cs), do: cs.action

  # If you manually add an error to a cs, that error won't be
  # displayed unless you also remember to set the action to non-nil
  @spec ensure_forms_display_errors(Changeset.t()) :: Changeset.t()
  def ensure_forms_display_errors(cs) do
    {:error, new_cs} =
      Changeset.apply_action(cs, :insert)
    new_cs
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

  def add_as_visible_error(changeset, field, message) do
    changeset
    |> Changeset.add_error(field, message)
    |> ensure_forms_display_errors
  end

  def has_error?(changeset, field),
    do: Keyword.has_key?(changeset.errors, field)

  # ------------Groups of changesets--------------------

  def all_valid?(list), do: Enum.all?(list, &(&1.valid?))
  def all_valid?(top, list), do: top.valid? && all_valid?(list)

  # ------------Misc-------------------------------------

  def empty_text_field?(changeset, field) do
    value = newest!(changeset, field)
    value == nil || value == ""
  end

  @spec ids_marked_for_deletion(Changeset.t, :atom) :: MapSet.t(db_id())
  def ids_marked_for_deletion(container, list_field) do
      container
      |> Changeset.fetch_field!(list_field)
      |> Enum.filter(&(Changeset.get_change(&1, :delete, false)))
      |> Enum.map(&Changeset.get_field(&1, :id))
      |> MapSet.new
  end

  # ----------------Hidden---------------------------
  # Hiding textual values out of an excess of caution

  @hidden_string "--hidden--"

  def hide(changeset, fields) when is_list(fields) do
    Enum.reduce(fields, changeset, &hide(&2, &1))
  end

  def hide(changeset, field),
    do: put_in(changeset, path_to(field), @hidden_string)

  def hidden?(changeset, field) do
    has_new_value?(changeset, field) == false &&
      get_in(changeset, path_to(field)) == @hidden_string
  end

  defp path_to(field), do: [Access.key(:data), Access.key(field)]

  defp has_new_value?(cs, field), do: Map.has_key?(cs.changes, field)
end
