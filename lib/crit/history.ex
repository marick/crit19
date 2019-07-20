defmodule Crit.History do
  alias Crit.History.Audit
  alias Crit.Repo
  
  def record(event, event_owner, data) do
    map = %{event: event, event_owner: event_owner, data: data}
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
    Audit.Query.n_most_recent(n, event) |> Repo.all
  end


  def no_audit_match, do: {:error, "No audit records"}
end
