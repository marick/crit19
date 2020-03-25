defmodule CritWeb.CurrentUser.SettingsControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.CurrentUser.SettingsController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Exemplars.PasswordFocused
  alias Crit.Users


  defp session_with_unactivated_user(%{conn: conn}) do
    {:ok, %{user: user, token: token}} =
      Factory.string_params_for(:user)
      |> Users.create_unactivated_user(@institution)
    
    conn = Plug.Test.init_test_session(conn, token: token)
    
    [conn: conn, token_text: token.text, user: user]
  end

  describe "getting a token via a form /" do
    setup :session_with_unactivated_user

    defp action__fresh_password_form(conn, token_text),
      do: get_via_action(conn, :fresh_password_form, token_text)

    test "no matching token", %{conn: conn} do
      action__fresh_password_form(conn, "bogus token")
      |> assert_redirected_to_authorization_failure_path()
      |> assert_error_flash_has("does not exist")
      |> assert_error_flash_has("has probably expired")
    end

    test "successful form creation", %{conn: conn, token_text: token_text} do
      action__fresh_password_form(conn, token_text)
      |> assert_purpose(create_a_password_without_needing_an_existing_one())
      |> assert_will_post_to(:set_fresh_password)
    end
  end

  describe "setting the password for the first time /" do

    setup :session_with_unactivated_user
    @valid_password "something horse something something"

    defp action__set_fresh_password(conn, new_password, given_confirmation) do
      post_to_action(conn, :set_fresh_password,
        under(:password, PasswordFocused.params(new_password, given_confirmation)))
    end

    test "the password is acceptable", %{conn: conn, user: user} do
      action__set_fresh_password(conn, @valid_password, @valid_password)
      |> assert_logged_in(user, @institution)
      |> assert_no_token_in_session

      |> assert_redirected_home
      |> assert_info_flash_has("You have been logged in")

      Users.attempt_login(user.auth_id, @valid_password, @institution)
      |> assert_ok
    end


    test "something is wrong with the password",
      %{conn: conn, user: user, token_text: token_text} do

      action__set_fresh_password(conn, @valid_password, "WRONG")
      |> refute_logged_in
      |> assert_session_token(token_text)
      
      |> assert_purpose(create_a_password_without_needing_an_existing_one())
      |> assert_will_post_to(:set_fresh_password)
      |> assert_user_sees(Common.form_error_message())
      |> assert_user_sees("should be the same as the new password")

      Users.attempt_login(user.auth_id, @valid_password, @institution)
      |> assert_error
      
    end

    test "the token is missing", %{conn: conn, user: user} do
      # This could happen if the user submitted the change-password form
      # twice. It's a no-op
      action__set_fresh_password(conn, @valid_password, @valid_password)
      # Hits back button...
      action__set_fresh_password(conn, @valid_password, @valid_password)
      |> assert_logged_in(user, @institution)
      |> assert_no_token_in_session

      |> assert_redirected_home
      |> assert_info_flash_has("You have been logged in")
    end
  end
end
