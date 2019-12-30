defmodule CritWeb.PublicControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.CurrentUser.SessionController

  setup %{conn: conn} do
    [conn: Plug.Test.init_test_session(conn, [])]
  end

  describe "/" do 
    test "redirect a logged-in user to home page", %{conn: conn} do
      conn
      |> logged_in()
      |> get("/")
      |> assert_redirected_to(SessionController, :home)
    end

    test "unlogged-in user is given the chance to log in", %{conn: conn} do
      assert conn = get(conn, "/")
      |> assert_purpose(public_facing_page())
      |> assert_user_sees("Log in")
    end
  end
end
