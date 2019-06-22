defmodule CritWeb.PageController do
  use CritWeb, :controller

  def index(conn, _params) do
    render(conn, "index.html")
  end
end
