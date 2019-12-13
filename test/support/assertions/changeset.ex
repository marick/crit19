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

  defchain assert_unchanged(%Changeset{} = changeset) do
    changes = changeset.changes
    assert changes == %{}, "Fields have changed: `#{Map.keys(changes) |> inspect}`"
  end

  defchain assert_unchanged(%Changeset{} = changeset, field) when is_atom(field) do
    refute Map.has_key?(changeset.changes, field),
      "Field `#{inspect field}` has changed"
  end

  defchain assert_unchanged(%Changeset{} = changeset, fields) when is_list(fields),
    do: Enum.map fields, &(assert_unchanged changeset, &1)

  defchain assert_errors(%Changeset{} = changeset, list) do
    errors = errors_on(changeset)

    any_error_check = fn field ->
      assert Map.has_key?(errors, field),
        "There are no errors for field `#{inspect field}`"
    end

    message_check = fn field, expected ->
      any_error_check.(field)

      msg = """
      `#{inspect field}` is missing an error message.
      expected: #{inspect expected}
      actual:   #{inspect errors[field]}
      """
      
      assert expected in errors[field], msg
    end
    
    Enum.map(list, fn
      field when is_atom(field) ->
        assert any_error_check.(field)
      {field, expected} when is_binary(expected) ->
        message_check.(field, expected)
      {field, expecteds} when is_list(expecteds) ->
        Enum.map expecteds, &(message_check.(field, &1))
    end)
  end

  defchain assert_error(cs, arg2) when is_atom(arg2), do: assert_errors(cs, [arg2])
  defchain assert_error(cs, arg2),                    do: assert_errors(cs,  arg2)
end
