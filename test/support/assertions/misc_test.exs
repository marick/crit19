defmodule Crit.Assertions.MiscTest do
  use ExUnit.Case, async: true
  import Crit.Assertions.Misc
  import Crit.Assertions.Assertion
  alias Crit.Users.Schemas.{PermissionList,User}

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


  describe "assert_shape" do
    test "structs" do
      
      (permission_list = %PermissionList{view_reservations: true})
      |> assert_shape( %{})
      |> assert_shape(%PermissionList{})
      |> assert_shape(%PermissionList{view_reservations: true})

      assertion_fails_with_diagnostic(
        ["The value doesn't match the given pattern"],
        fn -> 
          assert_shape(permission_list, %User{})
        end)
      
      assertion_fails_with_diagnostic(
        ["The value doesn't match the given pattern"],
        fn -> 
          assert_shape(permission_list, %PermissionList{view_reservations: false})
        end)
    end

    test "shapes with arrays" do
      assert_shape([1], [_])
      assert_shape([1], [_ | _])
      assert_shape([1, 2],  [_ | _])
      assertion_fails_with_diagnostic(
        ["The value doesn't match the given pattern"],
        fn -> assert_shape(no_op([1]), []) end)

      assertion_fails_with_diagnostic(
        ["The value doesn't match the given pattern"],
        fn -> assert_shape(no_op([1]), [2]) end)

      assertion_fails_with_diagnostic(
        ["The value doesn't match the given pattern"],
        fn -> assert_shape(no_op([1, 2]), [_,  _ , _]) end)
    end
  end

  # This prevents impossible matches from being flagged at compile time.
  defp no_op(list), do: list
  
end

