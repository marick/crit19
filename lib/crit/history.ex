defmodule Crit.History do
  alias Crit.History.Audit
  alias Crit.Repo
  
  def record(event, event_owner, data) do
    map = %{event: event, event_owner: event_owner, data: data}
    %Audit{}
    |> Audit.changeset(map)
    |> Repo.insert!
  end
end
