defmodule CritWeb.CurrentUser.SettingsController do
  use CritWeb, :controller
  alias Crit.Users
  alias Ecto.Changeset
  import CritWeb.SingletonIsh

  # No plugs are needed yet.

  def path(action), do: Routes.current_user_settings_path(Endpoint, action)
  def path(action, param), do: Routes.current_user_settings_path(Endpoint, action, param)


  def fresh_password_form(conn, %{"token_text" => token_text}) do
    case Users.user_from_token(token_text) do
      {:ok, _} ->
        conn
        |> put_session(:token_text, token_text)
        |> render_password_creation_form(Users.fresh_password_changeset())
      {:error, _} -> 
        conn
        |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
        |> redirect(to: Routes.public_path(conn, :index))
    end
  end

  def set_fresh_password(conn, %{"password" => params}) do
    with(
      {:ok, user} <- Users.user_from_token(get_session(conn, :token_text)),
      :ok <- Users.set_password(user.auth_id, params, institution(conn))
    ) do
      Users.delete_password_token(user.id)
      conn
      |> put_session(:user_id, user.id)
      |> delete_session(:token_text)
      |> put_flash(:info, "You have been logged in.")
      |> redirect(to: Routes.public_path(conn, :index))
    else
      {:error, %Changeset{} = changeset} ->
        conn
        |> Common.form_error_flash
        |> render_password_creation_form(changeset)
        
      # Missing token should be impossible.
      # Once there's logging, this can just produce a 500 message?
      {:error, message} ->
        conn
        |> put_flash(:error, """
        Something has gone wrong. Please report this problem: #{message}
        """)
        |> redirect(to: Routes.public_path(conn, :index))
    end
  end

  defp render_password_creation_form(conn, changeset) do
    render(conn, "fresh_password.html",
      path: path(:set_fresh_password),
      changeset: changeset)
  end
end
