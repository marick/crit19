defmodule CritWeb.CurrentUser.SessionController do
  use CritWeb, :controller
  alias Crit.Users
  import CritWeb.Plugs.Authorize

  plug :must_be_logged_in when action in [:logout]
  plug :must_be_logged_out when action not in [:logout]

  def path(args), do: apply(Routes, :current_user_session_path, args)


  def get_login_form(conn, _params) do
    render_login(conn, %{})
  end

  def try_login(conn, %{"login" => params}) do
    auth_id = params["auth_id"]
    password = params["password"]
    case Users.check_password(auth_id, password) do
      :ok ->
        redirect(conn, to: Routes.public_path(conn, :index))
      :error ->
        conn
        |> Common.form_error_flash
        |> render_login(params)
    end
  end

  def logout(conn, _params) do
    conn
    |> configure_session(drop: true)
    |> put_flash(:info, "You have been logged out.")
    |> redirect(to: Routes.public_path(conn, :index))
  end

  defp render_login(conn, params) do
    conn
    |> render("login_form.html",
         auth_id: params["auth_id"],
         path: path([conn, :try_login]))
  end

end
