defmodule Crit.Assertions.Map do
  import Crit.Assertions.Defchain
  import ExUnit.Assertions

  @doc """
  Test the existence and value of multiple fields with a single assertion:

      assert_fields(some_map, key1: 12, key2: "hello")

  Alternately, you can test just for existence:

      assert_fields(some_map, [:key1, :key2]

  The second argument needn't contain all of the fields in the value under
  test. 

  In case of success, the first argument is returned so that making multiple
  assertions about the same value can be done without verbosity:

      some_map
      |> assert_fields([:key1, :key2])
      |> assert_something_else
    
  """

  # Credit: Steve Freeman inspired this and improved on my original notation.
  defchain assert_fields(kvs, list) do
    assert_present = fn key -> 
      assert Map.has_key?(kvs, key), "Field `#{inspect key}` is missing"
    end
    
    list
    |> Enum.map(fn
      {key, expected} ->
        assert_present.(key)
        assert_extended_equality(Map.get(kvs, key), expected, key)
      key ->
        assert_present.(key)
    end)
  end

  @doc """
  Same as `assert_fields` but more pleasingly grammatical
  when testing only one field:

      assert_field(some_map, key: "value")

  When checking existence, you don't have to use a list:

      assert_field(some_map, :key)
  """
  defchain assert_field(kvs, list) when is_list(list) do
    assert_fields(kvs, list)
  end

  defchain assert_field(kvs, singleton) do
    assert_fields(kvs, [singleton])
  end


  @doc """
    An equality comparison of two maps, except leaving out some keys.

        assert_copy(old, new, except: [:name, :lock_version, :updated_at])

    Convenient when you want to tersely state that some values *didn't*
    change:

        update_for_success(original.id, params)
        |> assert_field(name: "New Name")
        |> assert_copy(original,
                       except: [:name, :lock_version, :updated_at])
        |> assert_copy(AnimalApi.get(original.id),
                       except: [:updated_at])
  """
  defchain assert_copy(left, right, opts \\ []) do
    keys = Keyword.get(opts, :except, [])
    assert Map.drop(left, keys) == Map.drop(right, keys)
  end

  defp assert_extended_equality(actual, predicate, key) when is_function(predicate) do
    msg = "#{inspect key} => #{inspect actual} fails predicate #{inspect predicate}"
    assert(predicate.(actual), msg)
  end

  defp assert_extended_equality(actual, expected, key) do
    msg =
      """
      `#{inspect key}` has the wrong value.
      actual:   #{inspect actual}
      expected: #{inspect expected}
      """
    assert(actual == expected, msg)
  end
end
