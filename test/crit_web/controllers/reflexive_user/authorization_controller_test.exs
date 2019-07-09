defmodule CritWeb.UserManagement.AuthorizationControllerTest do
  use CritWeb.ConnCase

  alias Crit.Users


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
      assert html_response(conn, 200) =~ "method=\"post\""

      post_to = path([conn, :fresh_password])
      assert html_response(conn, 200) =~ "action=\"#{post_to}\""
    end
  end

  defp flash_error(conn),
    do: get_session(conn, :phoenix_flash)["error"]

  defp path(args) do
    apply(Routes, :reflexive_user_authorization_path, args)
  end

  defp get_via_action(args) do 
    conn = hd(args)
    get(conn, path(args))
  end
end
