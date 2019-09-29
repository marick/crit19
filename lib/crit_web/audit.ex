defmodule CritWeb.Audit do
  import CritWeb.Plugs.Accessors
  alias Crit.Audit.CreationStruct
  alias Crit.Users.User

  def created_user(conn, %User{} = user) do
    log(conn, "created user", %{user_id: user.id, auth_id: user.auth_id})
  end

  def created_animals(conn, _stuff) do
    conn
  end

  ## UTIL

  defp log(conn, event, data) do
    send_struct(conn,
      %CreationStruct{event: event,
                      event_owner_id: user_id(conn),
                      data: data})
    conn
  end

  defp send_struct(conn, struct),
    do: apply(
          audit_server(conn),
          :put,
          [audit_pid(conn), struct, institution(conn)]
        )
end

