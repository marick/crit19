defmodule Ecto.ChangesetX do
  alias Ecto.Changeset

  # Phoenix `form_for` only displays errors when the `action` field 
  # is non-nil.
  def represents_form_errors?(changeset), do: changeset.action

  # If you manually add an error to a changeset, that error won't be
  # displayed unless you also remember to set the action to non-nil
  def ensure_forms_display_errors(changeset) do
    {:error, new_changeset} = 
      Changeset.apply_action(changeset, :insert)
    new_changeset
  end

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
  
  defp path_to(field), do: [Access.key(:data), Access.key(field)]
    
end
