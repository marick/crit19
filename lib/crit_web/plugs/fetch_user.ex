defmodule CritWeb.Plugs.FetchUser do
  import CritWeb.Plugs.Accessors
  alias Crit.Users.UserApi

  def init(opts), do: opts

  def call(conn, _opts) do
    id = user_id(conn)
    
    cond do
      # This clause supports testing
      has_user?(conn) ->
        conn

      user = id &&
          UserApi.permissioned_user_from_id(id, institution(conn)) -> 
        put_current_user(conn, user)

      true ->
        delete_current_user(conn)
    end
  end
end
