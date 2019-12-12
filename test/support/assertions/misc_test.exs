defmodule Crit.Assertions.MiscTest do
  use ExUnit.Case, async: true
  import Crit.Assertions.Misc

  test "ok" do
    :ok = assert_ok(:ok)
    {:ok, :not_examined} = assert_ok({:ok, :not_examined})
    assert_raise(ExUnit.AssertionError, fn ->
      assert_ok(:error)
    end)
  end

  test "error" do
    :error = assert_error(:error)
    {:error, :not_examined} = assert_error({:error, :not_examined})
    assert_raise(ExUnit.AssertionError, fn ->
      assert_error({:ok, 5})
    end)
  end
end

