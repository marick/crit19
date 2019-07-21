defmodule Crit.History.AuditEvents do
  @event_map %{
    created_user: "created user",
    login: "login",
  }
  
  def to_string(atom) do
    Map.fetch!(@event_map, atom)
  end
end
  
