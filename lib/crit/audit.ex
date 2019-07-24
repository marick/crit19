defmodule Crit.Audit do
  defstruct event_owner_id: nil, event: nil, data: %{}

  def created_user(conn, user_id, auth_id) do
    log(conn, "created user", %{user_id: user_id, auth_id: auth_id})
  end

  ## UTIL

  defmodule Crit.Audit.Conn do
    def server(conn), do: conn.assigns.audit_server
    def pid(conn), do: conn.assigns.audit_pid

    def entry_to_conn_server(conn, entry),
      do: apply(server(conn), :put, [pid(conn), entry])
  end

  defp log(conn, event, data) do
    owner_id = Plug.Conn.get_session(conn, :user_id)
    entry = %__MODULE__{event: event, event_owner_id: owner_id, data: data}
    Crit.Audit.Conn.entry_to_conn_server(conn, entry)
    conn
  end

end

