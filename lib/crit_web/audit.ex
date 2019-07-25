defmodule CritWeb.Audit do
  import CritWeb.DataAccessors
  alias Crit.Audit.CreationStruct

  def created_user(conn, user_id, auth_id) do
    log(conn, "created user", %{user_id: user_id, auth_id: auth_id})
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
    do: apply(audit_server(conn), :put, [audit_pid(conn), struct])
end

