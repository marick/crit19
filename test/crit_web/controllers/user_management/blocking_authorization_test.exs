defmodule CritWeb.UserManagement.BlockingAuthorizationTest do
  use CritWeb.ConnCase
  alias CritWeb.UserManagement.UserController

  test "An attempt to reach the UserController without a login redirects",
    %{conn: conn} do
    
    conn = get conn, UserController.path(:new)
    assert_failed_authorization(conn)
  end

end

