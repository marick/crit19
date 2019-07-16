defmodule CritWeb.ReflexiveUser.AuthorizationController do
  use CritWeb, :controller
  alias Crit.Users
  alias Ecto.Changeset
  import CritWeb.Plugs.Authorize

  plug :must_be_logged_in when action in [:logout]
  plug :must_be_logged_out when action not in [:logout]

  def path(args), do: apply(Routes, :reflexive_user_authorization_path, args)


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
      :ok <- Users.set_password(user.auth_id, params)
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
      path: path([conn, :set_fresh_password]),
      changeset: changeset)
  end


  # 

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
        render_login(conn, params)
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
    |> Common.form_error_flash
    |> render("login_form.html",
         auth_id: params["auth_id"],
         path: path([conn, :try_login]))
  end

end
