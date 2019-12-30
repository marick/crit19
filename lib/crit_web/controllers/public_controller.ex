defmodule CritWeb.PublicController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :public_path
  alias CritWeb.CurrentUser.SessionController

  def index(conn, _params) do
    if has_user?(conn) do 
      render(conn, "index.html")
    else
      redirect(conn, to: SessionController.path(:get_login_form))
    end
  end
end
