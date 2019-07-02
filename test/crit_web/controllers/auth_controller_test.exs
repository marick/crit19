defmodule CritWeb.AuthControllerTest do
  use CritWeb.ConnCase
  alias Ueberauth.Strategy.Helpers
  alias Crit.Accounts.PasswordToken

  describe "request" do
    test "renders the login page", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :request, :identity))
      assert html_response(conn, 200) =~ "method=\"post\""
      assert html_response(conn, 200) =~ "action=\"#{Helpers.callback_url(conn)}\""
    end
  end

  describe "credential check" do
    setup do
      data = %{ 
        auth_id:  "valid",
        wrong_id: "INVALID",
        password: "a valid password",
      }

      user = saved_user(auth_id: data.auth_id, password: data.password)
      
      [data: Map.put(data, :user, user)]
    end

    @tag :skip
    test "succeeds", %{conn: conn, data: data} do
      conn = post(conn, Routes.auth_path(conn, :identity_callback),
        auth_id: data.auth_id, password: data.password)
      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert get_session(conn, :current_user) == data.user
      assert get_session(conn, :phoenix_flash)["info"] =~ "Success"
    end
    
    test "fails", %{conn: conn, data: data} do
      conn = post(conn, Routes.auth_path(conn, :identity_callback),
        auth_id: data.wrong_id, password: data.password)
      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert get_session(conn, :phoenix_flash)["error"] =~ "wrong"
    end
  end

  describe "handling new password token" do
    test "no token found" do
      # token_text = PasswordToken.suitable_text()
      # conn = get(conn, Routes.auth_path(conn, :new_fresh_password, token_text))
      # assert redirected_to(conn) == Routes.page_path(conn, :index)
    end
  end

  describe "deleting the session" do
    @tag :skip
    test "is logout", %{conn: conn} do
    end
  end
end
