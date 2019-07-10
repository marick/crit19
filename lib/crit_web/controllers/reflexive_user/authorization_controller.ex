defmodule CritWeb.ReflexiveUser.AuthorizationController do
  use CritWeb, :controller
  alias Crit.Users

  def template_file(file), do: "reflexive_user/authorization/" <> file
  def path(args), do: apply(Routes, :reflexive_user_authorization_path, args)


  def fresh_password_form(conn, %{"token_text" => token_text}) do
    case Users.user_from_token(token_text) do
      {:ok, _} ->
        conn
        |> put_session(:token_text, token_text)
        |> render("fresh_password.html",
              path: path([conn, :set_fresh_password]),
              changeset: Users.fresh_password_changeset())
      {:error, _} -> 
        conn
        |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
        |> redirect(to: Routes.public_path(conn, :index))
    end
  end

  def set_fresh_password(conn, %{"password" => params}) do
    case Users.user_from_token(get_session(conn, :token_text)) do
      {:ok, user} ->
        case Users.set_password(user.auth_id, params) do
          :ok ->
            Users.delete_password_token(user.id)
            conn
            |> put_session(:user_id, user.id)
            |> delete_session(:token_text)
            |> put_flash(:info, "You have been logged in.")
            |> redirect(to: Routes.public_path(conn, :index))
        end
    end
  end

end
