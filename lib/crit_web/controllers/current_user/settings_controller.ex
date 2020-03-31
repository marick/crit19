defmodule CritWeb.CurrentUser.SettingsController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :current_user_settings_path
  alias Crit.Users.{UserApi,PasswordApi}
  alias Crit.Users.UniqueId
  alias Ecto.Changeset
  alias CritWeb.{PublicController, CurrentUser.SessionController}

  # No authentication is needed yet

  def fresh_password_form(conn, %{"token_text" => token_text}) do
    case UserApi.one_token(token_text) do
      {:ok, token} ->
        conn
        |> remember_token(token)
        |> render_password_creation_form(PasswordApi.fresh_password_changeset())
      {:error, _} -> 
        conn
        |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
        |> redirect(to: PublicController.path(:index))
    end
  end

  def set_fresh_password(conn, %{"password" => params}) do
    case UserApi.redeem_password_token(token(conn), params) do
      {:ok, %UniqueId{} = unique_id} ->
        conn
        |> forget_token
        |> SessionController.successful_login(unique_id)
      {:error, %Changeset{} = changeset} ->
        conn
        |> Common.form_error_flash
        |> render_password_creation_form(changeset)
    end
  end

  defp render_password_creation_form(conn, changeset) do
    conn
    |> put_layout("blank.html")
    |> render("fresh_password.html",
              path: path(:set_fresh_password),
              changeset: changeset)
  end
end
