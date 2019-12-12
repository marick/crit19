defmodule Crit.Assertions.Misc do
  import ExUnit.Assertions
  
  def assert_ok(:ok), do: :ok
  def assert_ok({:ok, _} = value), do: value
  def assert_ok(value), do: assert value == :ok # failure with nice error

  def assert_error(:error), do: :error
  def assert_error({:error, _} = value), do: value
  def assert_error(value), do:  assert value == :error # failure with nice error
end
