defmodule CritWeb.ReflexiveUser.AuthorizationController do
  use CritWeb, :controller
  alias Crit.Users

  def template_file(file), do: "reflexive_user/authorization/" <> file
  def path(args), do: apply(Routes, :reflexive_user_authorization_path, args)

  def fresh_password_form(conn, %{"token_text" => token_text}) do
    case Users.user_id_from_token(token_text) do
      {:ok, _} ->
        conn
        |> put_session(:token_text, token_text)
        |> render("fresh_password.html",
              path: path([conn, :set_fresh_password]),
              changeset: Users.fresh_password_changeset())
      :error -> 
        conn
        |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
        |> redirect(to: Routes.public_path(conn, :index))
    end
  end

end
