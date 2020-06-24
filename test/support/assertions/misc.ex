defmodule Crit.Assertions.Misc do
  import ExUnit.Assertions
  import Crit.Assertions.Defchain
  
  # Note: It would be nice to use
  #     assert_shape(thing, User)
  # ... but it's too much work to look the symbol `:User` up in the environment.

  @doc """
  Assert that the matches a binding form. 

      assert_shape(thing, %User{})
      assert_shape(thing, [_ | _])

  """
  defmacro assert_shape(value, shape) do 
    pattern_string = Macro.to_string(shape)
    quote do 
      eval_once = unquote(value)
      assert(match?(unquote(shape), eval_once),
        """
        The value doesn't match the given pattern.
        value:   #{inspect eval_once}
        pattern: #{unquote(pattern_string)}
        """)
      eval_once
    end
  end

  def assert_ok(:ok), do: :ok
  def assert_ok({:ok, _} = value), do: value
  def assert_ok(value), do: assert value == :ok # failure with nice error

  def assert_error(:error), do: :error
  def assert_error({:error, _} = value), do: value
  def assert_error(value), do:  assert value == :error # failure with nice error

  def ok_payload(tuple) do
    assert {:ok, payload} = tuple
    payload
  end

  def error_payload(tuple) do
    assert {:error, payload} = tuple
    payload
  end

  def error2_payload(tuple, second) do
    assert {:error, ^second, payload} = tuple
    payload
  end

  def singleton_payload(value) do
    assert_shape(value, [_only])
    List.first(value)
  end

  def ok_id(x) do
    ok_payload(x).id
  end

  defchain assert_empty(value) do
    assert Enum.empty?(value)
  end

  def using_singleton_in(container, field, f) do
    container
    |> Map.get(field)
    |> singleton_payload
    |> f.()
  end
end
