defmodule Crit.History do
  alias Crit.History.Audit
  alias Crit.Repo
  alias Crit.History.AuditEvents
  
  
  def record(event, event_owner_id, data) do
    map = %{event: AuditEvents.to_string(event),
            event_owner_id: event_owner_id,
            data: data}
    %Audit{}
    |> Audit.changeset(map)
    |> Repo.insert!
  end

  def last_audit(event) do
    case last_n_audits(1, event) do
      [] -> no_audit_match()
      [result] -> {:ok, result}
    end
  end

  def last_n_audits(n, event) do
    n
    |> Audit.Query.n_most_recent(AuditEvents.to_string(event))
    |> Repo.all
  end


  def no_audit_match, do: {:error, "No audit records"}
end
