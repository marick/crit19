defmodule Crit.Audit do
  defstruct event_owner_id: nil, event: nil, data: %{}

  @persistent_audit_log Application.get_env(:crit, :persistent_audit_log)
  
  def created_user(event_owner, user_id, auth_id) do
    log("created user", event_owner, %{user_id: user_id, auth_id: auth_id})
  end


  # Private
  
  defp log(event, %{id: event_owner_id}, data),
    do: log(event, event_owner_id, data)

  defp log(event, id, data) do 
    entry = %__MODULE__{event: event, event_owner_id: id, data: data}
    @persistent_audit_log.put(entry)
  end
end

