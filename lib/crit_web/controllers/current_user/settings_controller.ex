defmodule CritWeb.CurrentUser.SettingsController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :current_user_settings_path
  alias Crit.Users
  alias Ecto.Changeset
  alias Crit.Sql

  # No plugs are needed yet.

  def fresh_password_form(conn, %{"token_text" => token_text}) do
    case Users.one_token(token_text) do
      {:ok, token} ->
        conn
        |> put_token(token)
        |> render_password_creation_form(Users.fresh_password_changeset())
      {:error, _} -> 
        conn
        |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
        |> redirect(to: Routes.public_path(conn, :index))
    end
  end

  def set_fresh_password(conn, %{"password" => params}) do
    # TEMP KLUDGE
    user = Sql.get(Users.User, token(conn).user_id, token(conn).institution_short_name)
    case Users.set_password(user.auth_id, params, token(conn).institution_short_name) do
      :ok ->
        Users.delete_password_token(token(conn).text)
        conn
        |> put_user_id(user.id)
        |> put_institution(token(conn).institution_short_name)
        |> delete_session(:token)
        |> put_flash(:info, "You have been logged in.")
        |> redirect(to: Routes.public_path(conn, :index))
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
