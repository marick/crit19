defmodule CritWeb.PublicController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :public_path

  def index(conn, params) do
    if has_user?(conn) do 
      render(conn, "index.html")
    else
      redirect_to_login(conn, params)
    end
  end

  defp redirect_to_login(conn, _params) do
    path = Routes.current_user_session_path(conn, :get_login_form)
    redirect(conn, to: path)
  end
end
