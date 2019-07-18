defmodule CritWeb.PublicController do
  use CritWeb, :controller

  # Test support
  def path(args), do: apply(Routes, :public_path, args)

  
  def index(conn, _params) do
    render(conn, "index.html")
  end

  def redirect_to_login(conn, _params) do
    path = Routes.current_user_session_path(conn, :get_login_form)
    redirect(conn, to: path)
  end
end
