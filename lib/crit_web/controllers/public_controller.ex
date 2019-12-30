defmodule CritWeb.PublicController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :public_path
  alias CritWeb.CurrentUser.SessionController

  def index(conn, _params) do
    if has_user?(conn) do
      redirect(conn, to: SessionController.path(:home))
    else
      conn
      |> put_layout("public.html")
      |> render("index.html")
    end
  end
end
