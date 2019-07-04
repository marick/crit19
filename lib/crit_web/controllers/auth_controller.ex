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

  def identity_callback(%{assigns: %{ueberauth_auth: auth}} = conn, _params) do
    auth_id = auth.extra.raw_info["auth_id"]
    password = auth.credentials.other.password
    case Accounts.authenticate_user(auth_id, password) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "Successfully authenticated.")
        |> create_session(user)
        |> redirect(to: "/")
      :error ->
        conn
        |> put_flash(:error, "Password or name is wrong.")
        |> redirect(to: "/")
    end
  end

  defp create_session(conn, user) do
    conn
    |> put_session(:current_user, user)
    |> configure_session(renew: true)
  end

  def fresh_password_form(conn, %{"token_text" => token_text}) do
    case Accounts.user_from_unexpired_token(token_text) do
      {:ok, user} ->
        conn
        |> create_session(user)
        |> render("fresh_password.html",
              path: Routes.auth_path(conn, :fresh_password),
              token_text: token_text)
      :error -> 
        conn
        |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
        |> redirect(to: Routes.page_path(conn, :index))
    end
  end

  def fresh_password(conn, params) do
  end
    
end
