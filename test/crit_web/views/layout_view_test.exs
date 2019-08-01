defmodule CritWeb.LayoutViewTest do
  use CritWeb.ConnCase, async: true
  import CritWeb.LayoutView
  import Phoenix.HTML
  alias CritWeb.CurrentUser.SessionController

  describe "the login/logout link" do
    test "logged out", %{conn: conn} do
      actual =
        conn
        |> appropriate_session_link
        |> safe_to_string

      assert actual =~ "Log in"
      assert actual =~ SessionController.path([conn, :try_login])
    end

    test "logged in", %{conn: conn} do
      actual =
        conn
        |> logged_in()
        |> appropriate_session_link
        |> safe_to_string
      assert actual =~ "Log out"
      assert actual =~ SessionController.path([conn, :logout])
    end
  end
  
end
