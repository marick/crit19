defmodule CritWeb.Plugs.AuthorizeTest do
  use CritWeb.ConnCase, async: true
  alias CritWeb.Plugs.Authorize
  import Crit.DataExtras
  import Crit.PlugExtras

  setup %{conn: conn}, do: plug_setup(conn)

  def logged_in_with_irrelevant_permissions(conn) do
    user = Factory.build(:user)
    assert_without_permissions(user)
    assign(conn, :current_user, user)
  end
    


  describe "must be logged out" do
    test "is logged out", %{conn: conn} do
      conn = Authorize.must_be_logged_out(conn, [])
      refute conn.halted 
    end

    test "is logged in", %{conn: conn} do
      conn =
        conn
        |> logged_in_with_irrelevant_permissions
        |> Authorize.must_be_logged_out([])

      assert conn.halted 
      assert_redirected_to_authorization_failure_path(conn)
      assert flash_error(conn) =~ "already logged in"
    end
  end

  describe "must be logged in" do
    test "is logged out", %{conn: conn} do
      conn = Authorize.must_be_logged_in(conn, [])
      assert conn.halted 
      assert_redirected_to_authorization_failure_path(conn)
      assert flash_error(conn) =~ "must be logged in"

    end

    test "is logged in", %{conn: conn} do
      conn =
        conn
        |> logged_in_with_irrelevant_permissions
        |> Authorize.must_be_logged_in([])
      refute conn.halted 
    end
  end

  @permission :manage_and_create_users

  describe "requirement for an appropriate permission" do
    test "is logged out", %{conn: conn} do
      conn = Authorize.must_be_able_to(conn, @permission)
      assert conn.halted 
      assert_redirected_to_authorization_failure_path(conn)
      assert flash_error(conn) =~ "not authorized"
    end

    test "logged in, but inappropriate permissions", %{conn: conn} do
      wrong = Factory.build(:permission_list, %{@permission => false})
      conn =
        conn
        |> logged_in_with_permissions(wrong)
        |> Authorize.must_be_able_to(@permission)
      assert conn.halted
      assert_failed_authorization(conn)
    end

    test "logged in, with inappropriate permissions", %{conn: conn} do
      right = Factory.build(:permission_list, %{@permission => true})
      conn =
        conn
        |> logged_in_with_permissions(right)
        |> Authorize.must_be_able_to(@permission)
      refute conn.halted
    end
  end
end
