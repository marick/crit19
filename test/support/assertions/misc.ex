defmodule Crit.Assertions.Misc do
  import ExUnit.Assertions
  
  def assert_ok(:ok), do: true
  def assert_ok({:ok, _}), do: true
  def assert_ok(value), do: assert value == :ok # failure with nice error

  def assert_error(:error), do: true
  def assert_error({:error, _}), do: true
  def assert_error(value), do:  assert value == :ok # failure with nice error
end
