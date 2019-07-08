defmodule CritWeb.ReflexiveUser.AuthorizationController do
  use CritWeb, :controller

  defp not_done(conn) do
    conn
    |> put_status(:not_found)
    |> text("not implemented")
  end

  def fresh_password_form(conn, %{"token_text" => _token_text}) do
    not_done(conn)
    # case Accounts.user_from_unexpired_token(token_text) do
    #   {:ok, user} ->
    #     conn
    #     |> SessionPlug.login(user)
    #     |> render("fresh_password.html",
    #           path: Routes.auth_path(conn, :fresh_password),
    #           changeset: User.update_changeset(%User{}, %{})) # TODO: Should not have direct reach into user
    #   :error -> 
    #     conn
    #     |> put_flash(:error, "The account creation token does not exist. (It has probably expired.)")
    #     |> redirect(to: Routes.page_path(conn, :index))
    # end
  end

end
