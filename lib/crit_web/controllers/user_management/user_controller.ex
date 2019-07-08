defmodule CritWeb.UserManagement.UserController do
  use CritWeb, :controller

  alias Crit.Users
  alias Crit.Users.User
  alias Crit.Users.PermissionList

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
    # embedded_changeset = PermissionList.changeset(%PermissionList{})
    # changeset = User.changeset(%User{permission_list: embedded_changeset})
    changeset = User.changeset(%User{})
    IO.inspect changeset
    IO.puts "988888888888888"
    IO.inspect changeset.data

    render(conn, "new.html", changeset: changeset)
  end

  def create(conn, %{"user" => _user_params}) do
    not_done(conn)
    # case Users.create_user(user_params) do
    #   {:ok, user} ->
    #     conn
    #     |> put_flash(:info, "User created successfully.")
    #     |> redirect(to: Routes.user_management_user_path(conn, :show, user))

    #   {:error, %Ecto.Changeset{} = changeset} ->
    #     render(conn, "new.html", changeset: changeset)
    # end
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
end
