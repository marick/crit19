defmodule Crit.Assertions.Misc do
  import ExUnit.Assertions
  
  def assert_ok(:ok), do: :ok
  def assert_ok({:ok, _} = value), do: value
  def assert_ok(value), do: assert value == :ok # failure with nice error

  def assert_error(:error), do: :error
  def assert_error({:error, _} = value), do: value
  def assert_error(value), do:  assert value == :error # failure with nice error

  def ok_payload(x) do
    assert {:ok, payload} = x
    payload
  end

  def error_payload(x) do
    assert {:error, payload} = x
    payload
  end

  @doc """
  Assert that the matches a binding form. 

      assert_shape(thing, %User{})
      assert_shape(thing, [_ | _])

  """

  # Note: It would be nice to use
  #     assert_shape(thing, User)
  # ... but it's too much work to look the symbol `:User` up in the environment.

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
end
