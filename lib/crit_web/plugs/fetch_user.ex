defmodule CritWeb.Plugs.FetchUser do
  import Plug.Conn
  alias CritWeb.Plugs.ConnUser, as: Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    user_id = get_session(conn, :user_id)

    cond do
      # This clause supports testing
      Conn.has_user?(conn) ->
        conn

      user = user_id && Crit.Users.permissioned_user_from_id(user_id) -> 
        assign(conn, :current_user, user)

      true ->
        assign(conn, :current_user, nil)
    end
  end
end
