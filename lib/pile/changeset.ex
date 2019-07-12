defmodule Pile.Changeset do

  def represents_form_errors?(changeset), do: changeset.action

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
end
