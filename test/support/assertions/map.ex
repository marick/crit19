defmodule Crit.Assertions.Map do
  import Crit.Assertions.Defchain
  import ExUnit.Assertions

  defchain assert_fields(kvs, list_or_map) do
    list_or_map
    |> Enum.into(%{})
    |> Enum.map(fn
      {key, expected} ->
        assert Map.has_key?(kvs, key)
        assert_extended_equality(Map.get(kvs, key), expected, key)
      key ->
        assert Map.has_key?(kvs, key)
    end)
  end

  defchain assert_field(kvs, list_or_map) do
    assert_fields(kvs, list_or_map)
  end

  defchain assert_copy(left, right, opts \\ []) do
    keys = Keyword.get(opts, :except, [])
    assert Map.drop(left, keys) == Map.drop(right, keys)
  end

  def assert_extended_equality(actual, predicate, key) when is_function(predicate) do
    msg = "#{inspect key} => #{inspect actual} fails predicate #{inspect predicate}"
    assert(predicate.(actual), msg)
  end

  def assert_extended_equality(actual, expected, key) do
    msg =
      """
      #{inspect key} has the wrong value.
      left: #{inspect actual}
      right #{inspect expected}
      """
    assert(actual == expected, msg)
  end
end
