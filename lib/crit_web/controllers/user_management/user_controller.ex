defmodule CritWeb.UserManagement.UserController do
  use CritWeb, :controller

  alias Crit.Users
  alias Crit.Users.User
  alias Crit.Users.PermissionList
  import Phoenix.HTML.Link, only: [link: 2]
  import Phoenix.HTML, only: [raw: 1, safe_to_string: 1]

  defp not_done(conn) do
    conn
    |> put_status(:not_found)
    |> text("not implemented")
  end

  def index(conn, _params) do
    not_done(conn)
    # users = Users.list_users()
    # render(conn, "index.html", users: users)
  end

  def new(conn, _params) do
    embedded_changeset = PermissionList.changeset(%PermissionList{})
    changeset = User.changeset(%User{permission_list: embedded_changeset})
    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => user_params}) do
    case Users.user_needing_activation(user_params) do
      {:ok, user} ->
        flash = instructions_in_lieue_of_email(conn, user)
        conn
        |> put_flash(:info, raw(flash))
        |> redirect(to: Routes.user_management_user_path(conn, :new))

      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end

  def show(conn, %{"id" => _id}) do
    not_done(conn)
    # user = Users.get_user!(id)
    # render(conn, "show.html", user: user)
  end

  def edit(conn, %{"id" => _id}) do
    not_done(conn)
    # user = Users.get_user!(id)
    # changeset = Users.change_user(user)
    # render(conn, "edit.html", user: user, changeset: changeset)
  end

  def update(conn, %{"id" => _id, "user" => _user_params}) do
    not_done(conn)
    # user = Users.get_user!(id)

    # case Users.update_user(user, user_params) do
    #   {:ok, user} ->
    #     conn
    #     |> put_flash(:info, "User updated successfully.")
    #     |> redirect(to: Routes.user_management_user_path(conn, :show, user))

    #   {:error, %Ecto.Changeset{} = changeset} ->
    #     render(conn, "edit.html", user: user, changeset: changeset)
    # end
  end


  defp instructions_in_lieue_of_email(conn, user) do
    url = Routes.reflexive_user_authorization_url(conn,
      :fresh_password_form,
      user.password_token.text)
    token_link = link(url, to: url) |> safe_to_string()
    email_link = link(user.email, to: "mailto://#{user.email}") |> safe_to_string()
    "Send #{email_link} email with this URL: #{token_link}"
  end
end
