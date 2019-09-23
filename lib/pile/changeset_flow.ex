defmodule Pile.ChangesetFlow do
  def given_all_form_values_are_present(changeset, continuation) do
    if changeset.valid? do
      continuation.(changeset)
    else
      changeset
    end
  end

  def given_prerequisite_values_exist(changeset, must_be_present, continuation) do
    values = Enum.map(must_be_present, fn key -> changeset.changes[key] end)

    if Enum.any?(values, &(&1 == nil)) do
      changeset
    else
      continuation.(values)
    end
  end
end
