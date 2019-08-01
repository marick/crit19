defmodule CritWeb.LayoutView do
  use CritWeb, :view
  alias CritWeb.CurrentUser.SessionController
  import CritWeb.SingletonIsh

  def appropriate_session_link(conn) do
    if has_user?(conn) do
      link "Log out", to: SessionController.path__new(:logout), method: "delete"
    else
      link "Log in", to: SessionController.path__new(:get_login_form)
    end
  end

  def flash(conn, class, key) do
    if get_flash(conn, key) do
      ~E"""
      <p class='notification <%= class %>' role='alert'>
         <%= get_flash(conn, key) %>
      </p>
      """
    end
  end
end
