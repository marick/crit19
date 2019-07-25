defmodule CritWeb.Audit do
  alias CritWeb.Plugs.ConnAudit
  alias CritWeb.Plugs.ConnUser
  alias Crit.Audit.CreationStruct

  def created_user(conn, user_id, auth_id) do
    log(conn, "created user", %{user_id: user_id, auth_id: auth_id})
  end

  ## UTIL

  defp log(conn, event, data) do
    owner_id = ConnUser.user_id(conn)
    entry = %CreationStruct{event: event, event_owner_id: owner_id, data: data}
    ConnAudit.send_struct(conn, entry)
    conn
  end

end

