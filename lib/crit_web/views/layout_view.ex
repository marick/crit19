defmodule CritWeb.LayoutView do
  use CritWeb, :view
  alias CritWeb.CurrentUser.SessionController
  import CritWeb.DataAccessors

  def appropriate_session_link(conn) do
    if has_user?(conn) do
      link "Log out", to: SessionController.path([conn, :logout]), method: "delete"
    else
      link "Log in", to: SessionController.path([conn, :get_login_form])
    end
  end
end
