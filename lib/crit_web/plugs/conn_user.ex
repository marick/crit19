defmodule CritWeb.Plugs.ConnUser do
  def user_id(conn), do: Plug.Conn.get_session(conn, :user_id)
end
