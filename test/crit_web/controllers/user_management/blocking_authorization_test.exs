defmodule CritWeb.UserManagement.BlockingAuthorizationTest do
  use CritWeb.ConnCase, async: true
  alias CritWeb.UserManagement.UserController

  test "An attempt to reach the UserController without a login redirects",
    %{conn: conn} do
    
    conn = get conn, UserController.path([conn, :new])
    assert_failed_authorization(conn)
  end

end

