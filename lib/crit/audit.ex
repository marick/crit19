defmodule Crit.Audit do
  defstruct event_owner_id: nil, event: nil, data: %{}

  @persistent_audit_log Application.get_env(:crit, :persistent_audit_log)
  
  def created_user(conn, user_id, auth_id) do
    log(conn, "created user", %{user_id: user_id, auth_id: auth_id})
  end


  # Private
  
  defp log(conn, event, data) do
    owner_id = Plug.Conn.get_session(conn, :user_id)
    entry = %__MODULE__{event: event, event_owner_id: owner_id, data: data}
    @persistent_audit_log.put(entry)
    conn
  end
end

