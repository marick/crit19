defmodule Crit.Assertions.MiscTest do
  use ExUnit.Case, async: true
  import Crit.Assertions.Misc

  test "assert_ok" do
    :ok = assert_ok(:ok)
    {:ok, :not_examined} = assert_ok({:ok, :not_examined})
    assert_raise(ExUnit.AssertionError, fn ->
      assert_ok(:error)
    end)
  end

  test "assert_error" do
    :error = assert_error(:error)
    {:error, :not_examined} = assert_error({:error, :not_examined})
    assert_raise(ExUnit.AssertionError, fn ->
      assert_error({:ok, 5})
    end)
  end

  # ----------------------------------------------------------------------------
  test "ok_payload" do
    assert "payload" == ok_payload({:ok, "payload"})
    assert_raise(ExUnit.AssertionError, fn ->
      ok_payload(:ok)
    end)
    assert_raise(ExUnit.AssertionError, fn ->
      ok_payload({:error, "payload"})
    end)
  end

  test "error_payload" do
    assert "payload" == error_payload({:error, "payload"})
    assert_raise(ExUnit.AssertionError, fn ->
      error_payload(:error)
    end)
    assert_raise(ExUnit.AssertionError, fn ->
      error_payload({:ok, "payload"})
    end)
  end
  
end

