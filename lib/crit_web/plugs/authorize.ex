defmodule CritWeb.Plugs.Authorize do
  alias Phoenix.Controller
  alias CritWeb.Router.Helpers, as: Routes
  import Plug.Conn
  import CritWeb.Plugs.Accessors

  def must_be_logged_out(conn, _opts) do
    if has_user?(conn) do
      oops(conn, "You are already logged in.")
    else
      conn
    end
  end

  def must_be_logged_in(conn, _opts),
    do: run conn, has_user?(conn), "You must be logged in."

  def must_be_able_to(conn, what) do
    user = current_user(conn)
    run(conn, user && Map.get(user.permission_list, what), 
      "You are not authorized to visit that page.")
  end

  defp run(conn, bool, message) do
    if bool do
      conn
    else
      oops conn, message
    end
  end

  defp oops(conn, message) do
    conn
    |> Controller.put_flash(:error, message)
    |> Controller.redirect(to: Routes.public_path(conn, :index))
    |> halt()
  end
end
