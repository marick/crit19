defmodule CritWeb.CurrentUser.SettingsController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :current_user_settings_path
  alias Crit.Users
  alias Crit.Users.UniqueId
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
    case Users.redeem_password_token(token(conn), params) do
      {:ok, %UniqueId{} = unique_id} ->
        conn
        |> forget_token
        |> SessionController.successful_login(unique_id.user_id, unique_id.institution)
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
