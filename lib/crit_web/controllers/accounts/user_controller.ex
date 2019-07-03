defmodule CritWeb.Accounts.UserController do
  use CritWeb, :controller

  alias Crit.Accounts
  alias Crit.Accounts.User
  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]

  def index(conn, _params) do
    users = Accounts.list_users()
    render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    changeset = Accounts.changeset(%User{})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Accounts.create_user(user_params) do
      {:ok, user} ->
        url = Routes.auth_url(conn, :fresh_password_form, user.password_token.text)
        token_link = link(url, to: url) |> safe_to_string()
        email_link = link(user.email, to: "mailto://#{user.email}") |> safe_to_string()
        flash = "Send #{email_link} email with this URL: #{token_link}"
         conn
        |> put_flash(:info, raw(flash))
        |> redirect(to: Routes.accounts_user_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => id}) do
    user = Accounts.get_user!(id)
    changeset = Accounts.changeset(user)
    render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => id, "user" => user_params}) do
    user = Accounts.get_user!(id)

    case Accounts.update_user(user, user_params) do
      {:ok, user} ->
        conn
        |> put_flash(:info, "User updated successfully.")
        |> redirect(to: Routes.accounts_user_path(conn, :show, user))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "edit.html", user: user, changeset: changeset)
    end
  end
end
