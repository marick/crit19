defmodule CritWeb.ReflexiveUser.AuthorizationControllerTest do
  use CritWeb.ConnCase
  alias Crit.Users
  alias CritWeb.ReflexiveUser.AuthorizationController, as: Own
  use Crit.Test.Controller, controller: Own

  describe "displaying a token to get a form" do
    setup do
      {:ok, user} = string_params_for_new_user() |> Users.user_needing_activation
      [token_text: user.password_token.text, user: user]
    end

    test "getting the form: there is no matching token", %{conn: conn} do
      conn = get_via_action [conn, :fresh_password_form, "bogus token"]
      assert redirected_to(conn) == Routes.public_path(conn, :index)
      assert flash_error(conn) =~ "does not exist"
      assert flash_error(conn) =~ "has probably expired"
    end

    test "getting the form: there is a matching token",
      %{conn: conn, token_text: token_text, user: user} do
      conn = get_via_action [conn, :fresh_password_form, token_text]

      assert_purpose conn, create_a_password_without_needing_an_existing_one()
      assert_will_post_to(conn, :set_fresh_password)
      assert get_session(conn, :token_text) == token_text

      # The token is not deleted.
      assert Users.user_has_password_token?(user.id)
    end
  end

  describe "setting the password for the first time" do
    setup %{conn: conn} do
      {:ok, user} = string_params_for_new_user() |> Users.user_needing_activation

      conn = Plug.Test.init_test_session(conn, token_text: user.password_token.text)

      run = fn conn, new_password, confirmation ->
        post_to_action([conn, :set_fresh_password], :password,
          password_params(new_password, confirmation))
      end
      
      [conn: conn, valid_password: "something horse something something",
       user: user, run: run]
    end

    test "the token is found and the password is acceptable",
      %{conn: conn, valid_password: valid_password, user: user, run: run} do

      conn = run.(conn, valid_password, valid_password)
      assert :ok == Users.check_password(user.auth_id, valid_password)
      assert get_session(conn, :user_id) == user.id
      refute get_session(conn, :token_text)

      # Token has been deleted
      refute Users.user_has_password_token?(user.id)
      assert redirected_to(conn) == Routes.public_path(conn, :index)
      assert flash_info(conn) =~ "You have been logged in"
    end

    test "the token is not found (should be impossible)",
      %{conn: conn, valid_password: valid_password, run: run} do
      conn =
        conn
        |> put_session(:token_text, "WRONG")
        |> run.(valid_password, valid_password)

      assert redirected_to(conn) == Routes.public_path(conn, :index)
      assert flash_error(conn) =~ "Something has gone wrong"
      assert flash_error(conn) =~ "Please report this problem:"
      assert flash_error(conn) =~ "missing token 'WRONG'"
    end

    test "something is wrong with the password", 
      %{conn: conn, user: user, valid_password: valid_password, run: run} do

      conn = run.(conn, valid_password, "WRONG")
      refute :ok == Users.check_password(user.auth_id, valid_password)
      assert_purpose conn, create_a_password_without_needing_an_existing_one()
      assert_will_post_to(conn, :set_fresh_password)

      assert html_response(conn, 200) =~ Common.form_error_message
      assert html_response(conn, 200) =~ "should be the same as the new password"
      # The token is not deleted.
      assert Users.user_has_password_token?(user.id)
    end
  end

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
      assert html_response(conn, 200) =~ Common.form_error_message
      assert html_response(conn, 200) =~ auth_id
      refute html_response(conn, 200) =~ password
      
      
    end
  end
end
