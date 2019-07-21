defmodule Servers.Audit do
  use GenServer
  alias Crit.History
  alias Crit.History.AuditEvents
  alias Crit.Users.User

  def created_user(event_owner, user_id, auth_id),
    do: log(:created_user, event_owner,
          %{user_id: user_id, auth_id: auth_id})


  def log(event, event_owner, data \\ %{})
 
  def log(event, %User{id: event_owner_id}, data),
    do: log(event, event_owner_id, data)

  def log(event, event_owner_id, data) do
    GenServer.cast(__MODULE__,
      {:log, event, event_owner_id, data})
  end

  def start_link(_),
    do: GenServer.start_link(__MODULE__, :no_value, name: __MODULE__)

  # Server part

  def init(initial_val) do
    {:ok, initial_val}
  end

  def handle_cast({:log, event, event_owner_id, data}, _) do
    History.record(event, event_owner_id, data)
    {:noreply, :no_value}
  end

end
