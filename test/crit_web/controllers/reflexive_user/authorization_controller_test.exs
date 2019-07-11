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

      assert_rendered(conn, "fresh_password.html")
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
      [conn: conn, valid_password: "something horse something something", user: user]
    end

    test "the token is found and the password is acceptable",
      %{conn: conn, valid_password: valid_password, user: user} do

      conn = post_to_action([conn, :set_fresh_password], :password,
        %{new_password: valid_password, new_password_confirmation: valid_password})
      assert :ok == Users.check_password(user.auth_id, valid_password)
      assert get_session(conn, :user_id) == user.id
      refute get_session(conn, :token_text)

      # Token has been deleted
      refute Users.user_has_password_token?(user.id)
      assert redirected_to(conn) == Routes.public_path(conn, :index)
      assert flash_info(conn) =~ "You have been logged in"
    end

    @tag :skip
    test "the token is not found (should be impossible)" do
    end

    @tag :skip
    test "something is wrong with the password" do
    end
  end
end
