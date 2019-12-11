defmodule CritWeb.CurrentUser.SettingsControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.CurrentUser.SettingsController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Exemplars.PasswordFocused
  alias Crit.Users
  alias CritWeb.PublicController

  describe "displaying a token to get a form /" do
    setup do
      {:ok, %{user: user, token: token}} = Factory.string_params_for(:user) |> Users.create_unactivated_user(@institution)
      [token_text: token.text, user: user]
    end

    test "getting the form: there is no matching token", %{conn: conn} do
      conn = get_via_action(conn, :fresh_password_form, "bogus token")
      assert redirected_to(conn) == PublicController.path(:index)
      assert flash_error(conn) =~ "does not exist"
      assert flash_error(conn) =~ "has probably expired"
    end

    test "getting the form: there is a matching token",
      %{conn: conn, token_text: token_text} do
      conn = get_via_action(conn, :fresh_password_form, token_text)

      assert_purpose conn, create_a_password_without_needing_an_existing_one()
      assert_will_post_to(conn, :set_fresh_password)
      assert {:ok, original_token} = Users.one_token(token_text)

      # Note that the date of the token put into the conn has been changed,
      # but at a one-second granularity.
      assert token(conn).text == original_token.text
      assert token(conn).user_id == original_token.user_id
      assert NaiveDateTime.diff(token(conn).updated_at, original_token.updated_at) >= 0
    end
  end

  describe "setting the password for the first time /" do

    @valid_password "something horse something something"

    defp action__set_fresh_password(conn, new_password, given_confirmation) do
      post_to_action(conn, :set_fresh_password,
        under(:password, PasswordFocused.params(new_password, given_confirmation)))
    end

    setup %{conn: conn} do
      {:ok, %{user: user, token: token}} =
        Factory.string_params_for(:user)
        |> Users.create_unactivated_user(@institution)

      conn = Plug.Test.init_test_session(conn, token: token)

      [conn: conn, user: user]
    end

    test "the password is acceptable", %{conn: conn, user: user} do
      action__set_fresh_password(conn, @valid_password, @valid_password)
      |> assert_logged_in(user, @institution)
      |> assert_token_deleted

      |> assert_redirected_home
      |> assert_info_flash("You have been logged in")

      Users.attempt_login(user.auth_id, @valid_password, @institution)
      |> assert_ok
    end

    test "something is wrong with the password", %{conn: conn, user: user} do
      conn = action__set_fresh_password(conn, @valid_password, "WRONG")
      assert :error ==
        Users.attempt_login(user.auth_id, @valid_password, @institution)
      assert_purpose conn, create_a_password_without_needing_an_existing_one()
      assert_will_post_to(conn, :set_fresh_password)
      refute user_id(conn)
      refute institution(conn) == @institution
      assert token(conn)

      assert_user_sees(conn, 
        [ Common.form_error_message(),
          "should be the same as the new password",
        ])
    end
  end

end
