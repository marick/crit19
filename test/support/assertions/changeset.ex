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
  The elements of `list` must be present in the `Changeset`'s changes.
  The simple case just checks whether fields have been changed:

      assert_changes(changeset, [:name, :tags])

  Alternately, you can check that the listed keys have particular values:

      assert_changes(changeset, name: "Bossie", tags: [])

  """
  defchain assert_changes(%Changeset{} = changeset, list),
    do: assert_fields(changeset.changes, list)

  @doc """
  `assert_change` can be used when only a single field is to have
  been changed. Its second argument is usually an atom, but can also
  be a list that's given directly to `assert_changes`. 

      assert_changes(changeset, :name)
      assert_changes(changeset, name: "Bossie")
  """
  def assert_change(cs, arg2) when not is_list(arg2),
    do: assert_changes(cs, [arg2])
  def assert_change(cs, arg2),
    do: assert_changes(cs, arg2)

  @doc """
  The changeset must contain no changes.
  """
  
  defchain assert_no_changes(%Changeset{} = changeset) do
    changes = changeset.changes
    assert changes == %{}, "Fields have changed: `#{Map.keys(changes) |> inspect}`"
  end

  @doc """
  Require that particular fields have no changes. Unmentioned fields may
  have changes. When there's only a single field, it needn't be enclosed in
  a list.

      assert_unchanged(changeset, :name)
      assert_unchanged(changeset, [:name, :tags])
  """
  defchain assert_unchanged(%Changeset{} = changeset, field) when is_atom(field) do
    assert_no_typo_in_struct_key(changeset.data, field)
    refute Map.has_key?(changeset.changes, field),
      "Field `#{inspect field}` has changed"
  end

  defchain assert_unchanged(%Changeset{} = changeset, fields) when is_list(fields),
    do: Enum.map fields, &(assert_unchanged changeset, &1)


  @doc """
  Assert that a changeset contains specific errors. In the simplest case,
  it requires that the fields have at least one error, but doesn't require
  any specific message:

      assert_errors(changeset, [:name, :tags])
  
  A message may also be required:

      assert_errors(changeset,
        name: "may not be blank",
        tags: "is invalid")

  The given string must be an exact match for one of the field's errors.
  (It is not a failure for others to be unmentioned.)

  If you want to list more than one message, enclose them in a list:

      assert_errors(changeset,
        name: "may not be blank",
        tags: ["is invalid",
               "has something else wrong"])

  The list need not be a complete list of errors.
  """
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

  @doc """
  Like `assert_error` but reads better when there's only a single error
  to be checked:

      assert_error(changeset, name: "is invalid")

  If the message isn't to be checked, you can use a single atom:

      assert_error(changeset, :name)
  """
  
  defchain assert_error(cs, arg2) when is_atom(arg2), do: assert_errors(cs, [arg2])
  defchain assert_error(cs, arg2),                    do: assert_errors(cs,  arg2)



  @doc """
  Require that none of the named fields have an associated error:

      assert_error_free(changes, [:in_service_datestring, :name])
  
  There can also be a singleton field:

      assert_error_free(changes, :in_service_datestring)
  """

  defchain assert_error_free(changeset, field) when is_atom(field),
    do: assert_error_free(changeset, [field])
  defchain assert_error_free(changeset, fields) do
    errors = errors_on(changeset)

    check = fn(field) ->
      assert_no_typo_in_struct_key(changeset.data, field)
      refute Map.has_key?(errors, field),
        "There is an error for field `#{inspect field}`"
    end
      
    Enum.map(fields, check)
  end

  defchain assert_original_data(changeset, keylist) when is_list(keylist) do
    assert_fields(changeset.data, keylist)
  end
  
  defchain assert_original_data(changeset, expected) do
    assert changeset.data == expected
  end
end
