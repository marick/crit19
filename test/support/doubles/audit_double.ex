defmodule Doubles.AuditDouble do
  use GenServer
  alias Crit.History.Audit
  alias Crit.Users.User

  def log(event, event_owner, data \\ %{})
 
  def log(event, %User{id: event_owner_id}, data),
    do: log(event, event_owner_id, data)

  def log(event, event_owner_id, data) do
    GenServer.call(__MODULE__,
      {:log, event, event_owner_id, data})
  end

  def latest(), do: GenServer.call(__MODULE__, :latest)

  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  # Server part

  def init(:ok) do
    {:ok, []}
  end

  def handle_call({:log, event, event_owner_id, data}, _from, state) do
    audit = %Audit{event_owner_id: event_owner_id,
                   event: event,
                   data: data}
    {:reply, :ok, [audit | state]}
  end

  def handle_call(:latest, _from, state) do
    {:reply, {:ok, List.first(state)}, state}
  end    

end
