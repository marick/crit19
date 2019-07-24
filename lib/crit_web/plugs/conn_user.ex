defmodule CritWeb.Plugs.ConnUser do
  def user_id(conn), do: Plug.Conn.get_session(conn, :user_id)

  def current_user(conn), do: conn.assigns.current_user

  def has_user?(conn), do: Map.get(conn.assigns, :current_user)
end
