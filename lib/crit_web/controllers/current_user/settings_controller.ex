defmodule CritWeb.CurrentUser.SettingsController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :current_user_settings_path
  alias Crit.Users
  alias Ecto.Changeset
  alias Crit.Sql
  alias CritWeb.{PublicController, CurrentUser.SessionController}

  # No plugs are needed yet.

  def fresh_password_form(conn, %{"token_text" => token_text}) do
    case Users.one_token(token_text) do
      {:ok, token} ->
        conn
        |> remember_token(token)
        |> render_password_creation_form(Users.fresh_password_changeset())
      {:error, _} -> 
        conn
        |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
        |> redirect(to: PublicController.path(:index))
    end
  end

  def set_fresh_password(conn, %{"password" => params}) do
    user_id = token(conn).user_id
    institution = token(conn).institution_short_name
    # Note: a transaction isn't useful here because the assumption that
    # users are never deleted (just inactivated) is pervasive in this code,
    # so the `get` "cannot" fail. 
    user = Sql.get(Users.User, user_id, institution)
    case Users.set_password(user.auth_id, params, institution) do
      :ok ->
        Users.delete_password_token(token(conn).text)
        conn
        |> forget_token
        |> SessionController.successful_login(user_id, institution)
      {:error, %Changeset{} = changeset} ->
        conn
        |> Common.form_error_flash
        |> render_password_creation_form(changeset)
    end
  end

  defp render_password_creation_form(conn, changeset) do
    render(conn, "fresh_password.html",
      path: path(:set_fresh_password),
      changeset: changeset)
  end
end
