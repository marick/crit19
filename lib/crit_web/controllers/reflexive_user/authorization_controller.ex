defmodule CritWeb.ReflexiveUser.AuthorizationController do
  use CritWeb, :controller
  alias Crit.Users

  defp not_done(conn) do
    conn
    |> put_status(:not_found)
    |> text("not implemented")
  end

  def fresh_password_form(conn, %{"token_text" => token_text}) do
    case Users.user_id_from_token(token_text) do
      {:ok, user_id} ->
        conn
        # |> SessionPlug.login(user)
        |> render("fresh_password.html",
              path: Routes.reflexive_user_authorization_path(conn, :fresh_password),
              changeset: Users.fresh_password_changeset())
      :error -> 
        conn
        |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
        |> redirect(to: Routes.public_path(conn, :index))
    end
  end

end
