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

  describe "setting a new password" do
    setup do
      user = saved_user()
      token_text = user.password_token.text

      [user: user, token_text: token_text]
    end

    
    test "getting the form: there is no matching token", %{conn: conn} do
      conn = get(conn, Routes.auth_path(conn, :fresh_password_form, "bogus token"))
      assert redirected_to(conn) == Routes.page_path(conn, :index)
      assert get_session(conn, :phoenix_flash)["error"] =~ "does not exist"
      assert get_session(conn, :phoenix_flash)["error"] =~ ~r{has.*expired}
    end

    test "getting the form: there is a matching token",
      %{conn: conn, user: user, token_text: token_text} do
      conn = get(conn, Routes.auth_path(conn, :fresh_password_form, token_text))
      assert html_response(conn, 200) =~ "method=\"post\""
      assert html_response(conn, 200) =~ "action=\"#{Routes.auth_path(conn, :fresh_password)}\""
      # stashes the token text in the form
      assert html_response(conn, 200) =~ token_text
    end

    @tag :skip
    test "receiving the form: it's rejected by the business logic",
      %{conn: conn, user: user, token_text: token_text} do
      fetch_session(conn)
      put_session(conn, :current_user, user)
      conn = post(conn, Routes.auth_path(conn, :fresh_password),
        new_password: "one version", password_confirmation: "WRONG WRONG WRONG",
        token_text: token_text)
      assert redirected_to(conn) == Routes.auth_path(conn, :fresh_password_form, token_text)
      assert get_session(conn, :phoenix_flash)["error"] =~ "should be the same"
    end
  end
  

  describe "deleting the session" do
    @tag :skip
    test "is logout", %{conn: conn} do
    end
  end
end
