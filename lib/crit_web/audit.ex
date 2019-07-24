defmodule CritWeb.Audit do
  defstruct event_owner_id: nil, event: nil, data: %{}

  alias CritWeb.Plugs.ConnAudit
  alias CritWeb.Plugs.ConnUser

  def created_user(conn, user_id, auth_id) do
    log(conn, "created user", %{user_id: user_id, auth_id: auth_id})
  end

  ## UTIL

  defp log(conn, event, data) do
    owner_id = ConnUser.user_id(conn)
    entry = %__MODULE__{event: event, event_owner_id: owner_id, data: data}
    ConnAudit.send_struct(conn, entry)
    conn
  end

end

