defmodule CritWeb.LayoutView do
  use CritWeb, :view
  alias CritWeb.CurrentUser.SessionController

  def appropriate_session_link(conn) do
    if Map.get(conn.assigns, :current_user) do
      link "Log out", to: SessionController.path([conn, :logout]), method: "delete"
    else
      link "Log in", to: SessionController.path([conn, :get_login_form])
    end
  end
end
