defmodule CritWeb.AuthController do
  use CritWeb, :controller
  plug Ueberauth
  alias Ueberauth.Strategy.Helpers
  alias Crit.Accounts

  def request(conn, _params) do
    render(conn, "request.html", url: Helpers.callback_url(conn))
  end

  def delete(conn, _params) do
    conn
    |> put_flash(:info, "You have been logged out!")
    |> configure_session(drop: true)
    |> redirect(to: "/")
  end

  def identity_callback(%{assigns: %{ueberauth_failure: _fails}} = conn, _params) do
    conn
    |> put_flash(:error, "Failed to log in.")
    |> redirect(to: "/")
  end

  def identity_callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    email = auth.info.email
    password = auth.credentials.other.password
    case Accounts.authenticate_user(email, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> put_session(:current_user, user)
        |> configure_session(renew: true)
        |> redirect(to: "/")
      :error ->
        conn
        |> put_flash(:error, "Password or name is wrong.")
        |> redirect(to: "/")
    end
  end
end
