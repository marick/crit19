defmodule CritWeb.PublicControllerTest do
  use CritWeb.ConnCase, async: true

  test "GET /", %{conn: conn} do
    assert conn = get(conn, "/")
  end

  test "shortcut login form", %{conn: conn} do
    assert conn = get(conn, "/login")
    assert redirected_to(conn) ==
      Routes.current_user_session_path(conn, :get_login_form)
  end
end
