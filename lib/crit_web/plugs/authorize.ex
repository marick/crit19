defmodule CritWeb.Plugs.Authorize do
  alias Phoenix.Controller
  alias CritWeb.Router.Helpers, as: Routes
  import Plug.Conn


  def must_be_logged_out(conn, _opts) do
    if conn.assigns.current_user do
      oops(conn, "You are already logged in.")
    else
      conn
    end
  end

  def must_be_logged_in(conn, _opts) do 
    if conn.assigns.current_user do
      conn
    else
      oops(conn, "You must be logged in.")
    end
  end

  @unauthorized "You are not authorized to visit that page."

  def oops(conn, message) do
    conn
    |> Controller.put_flash(:error, message)
    |> Controller.redirect(to: Routes.public_path(conn, :index))
    |> halt()
  end
end
