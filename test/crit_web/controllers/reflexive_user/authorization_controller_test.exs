defmodule CritWeb.ReflexiveUser.AuthorizationControllerTest do
  use CritWeb.ConnCase
  alias Crit.Users
  alias CritWeb.ReflexiveUser.AuthorizationController, as: Own
  use Crit.Test.Controller, controller: Own

  describe "displaying a token to get a form" do
    setup do
      {:ok, user} = user_creation_params() |> Users.user_needing_activation
      [token_text: user.password_token.text]
    end

    test "getting the form: there is no matching token", %{conn: conn} do
      conn = get_via_action [conn, :fresh_password_form, "bogus token"]
      assert redirected_to(conn) == Routes.public_path(conn, :index)
      assert flash_error(conn) =~ "does not exist"
      assert flash_error(conn) =~ "has probably expired"
    end

    test "getting the form: there is a matching token",
      %{conn: conn, token_text: token_text} do
      conn = get_via_action [conn, :fresh_password_form, token_text]

      assert_rendered(conn, "fresh_password.html")
      assert html_response(conn, 200) =~ "method=\"post\""
      post_to = Own.path([conn, :fresh_password])
      assert html_response(conn, 200) =~ "action=\"#{post_to}\""

      assert get_session(conn, :token_text) == token_text
    end
  end
end
