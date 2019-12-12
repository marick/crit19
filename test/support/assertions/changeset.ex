defmodule Crit.Assertions.Changeset do
  import Crit.Assertions.Defchain
  import ExUnit.Assertions
  import Crit.Extras.ChangesetT, only: [errors_on: 1]
  import Crit.Assertions.Map
  alias Ecto.Changeset

  defchain assert_valid(%Changeset{} = changeset),
    do: assert changeset.valid?

  defchain assert_invalid(%Changeset{} = changeset),
    do: refute changeset.valid?

  @doc """
  The elements of `list` must be present in 
  """
  defchain assert_changes(%Changeset{} = changeset, list),
    do: assert_fields(changeset.changes, list)

  def assert_change(cs, arg2) when not is_list(arg2),
    do: assert_changes(cs, [arg2])
  def assert_change(cs, arg2),
    do: assert_changes(cs, arg2)

  defchain assert_unchanged(%Changeset{} = changeset),
    do: assert changeset.changes == %{}

  defchain assert_unchanged(%Changeset{} = changeset, field) when is_atom(field) do
    refute Map.has_key?(changeset.changes, field)
  end

  defchain assert_unchanged(%Changeset{} = changeset, fields) when is_list(fields),
    do: Enum.map fields, &(assert_unchanged changeset, &1)

  defchain assert_errors(%Changeset{} = changeset, list) do
    errors = errors_on(changeset)

    message_check = fn field, expected ->
      assert Map.has_key?(errors, field)
      assert expected in errors[field]
    end
    
    Enum.map(list, fn
      field when is_atom(field) ->
        assert is_list(errors[field])
      {field, expected} when is_binary(expected) ->
        message_check.(field, expected)
      {field, expecteds} when is_list(expecteds) ->
        Enum.map expecteds, &(message_check.(field, &1))
    end)
  end

  defchain assert_error(cs, arg2) when is_atom(arg2), do: assert_errors(cs, [arg2])
  defchain assert_error(cs, arg2),                    do: assert_errors(cs,  arg2)
end
