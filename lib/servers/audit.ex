defmodule Servers.Audit do
  @audit Application.get_env(:crit, :audit_server_impl)

  def created_user(event_owner, user_id, auth_id),
    do: @audit.log(:created_user, event_owner,
          %{user_id: user_id, auth_id: auth_id})
end
