defmodule Crit.History do
  alias Crit.History.Audit
  alias Crit.Repo
  
  def record(event, event_owner, data) do
    map = %{event: event, event_owner: event_owner, data: data}
    %Audit{}
    |> Audit.changeset(map)
    |> Repo.insert!
  end

  def single_most_recent(event) do
    case n_most_recent(1, event) do
      [] -> no_audit_match()
      [result] -> {:ok, result}
    end
  end

  def n_most_recent(n, event) do
    Audit.Query.n_most_recent(n, event) |> Repo.all
  end


  def no_audit_match, do: {:error, "No audit records"}
end
