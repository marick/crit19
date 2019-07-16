defmodule CritWeb.CurrentUser.SessionControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.CurrentUser.SessionController, as: UnderTest
  use CritWeb.ConnShorthand, controller: UnderTest

  describe "handling a login" do
    test "first time has empty fields", %{conn: conn} do
      conn = get_via_action([conn, :get_login_form])
      assert_will_post_to(conn, :try_login)
      assert_purpose conn, show_login_form()
    end

    test "login failure leaves auth id visible but zeroes password field",
      %{conn: conn} do
      auth_id = "bogus auth id"
      password = "this is a bogus password"
      conn = post_to_action([conn, :try_login], :login,
        %{auth_id: auth_id, password: password})

      assert_purpose conn, show_login_form()
      assert_user_sees(conn, [Common.form_error_message, auth_id])
      refute_user_sees(conn, password)
    end

    test "successful login", %{conn: conn} do
      password = "password"
      user = user_with_password(password)
      conn = post_to_action([conn, :try_login], :login,
        %{auth_id: user.auth_id, password: password})
      assert redirected_to(conn) == Routes.public_path(conn, :index)
    end
  end

  describe "logout" do
    test "you can't log out if you're already logged out", %{conn: conn} do
      conn = delete_via_action([conn, :logout])
      assert redirected_to(conn) == Routes.public_path(conn, :index)
      assert get_flash(conn, :error) =~ "You must be logged in"
    end


    test "logout clears session", %{conn: conn} do
      conn = assign(conn, :current_user, Factory.build(:user))
      conn = delete_via_action([conn, :logout])

      assert redirected_to(conn) == Routes.public_path(conn, :index)
      assert get_flash(conn, :info) =~ "You have been logged out"
      refute get_session(conn, :user_id)
    end
  end
end
