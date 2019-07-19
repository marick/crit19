defmodule Servers.Audit do
  use GenServer
  alias Crit.History

  def log(event, event_owner, data \\ %{}), 
    do: GenServer.cast(__MODULE__, {:log, event, event_owner, data})
  

  def start_link(_) do
    GenServer.start_link(__MODULE__, :no_value, name: __MODULE__) 
  end

  def init(initial_val) do
    {:ok, initial_val}
  end

  def handle_cast({:log, event, event_owner, data}, _) do
    History.record(event, event_owner, data)
    {:noreply, :no_value}
  end
end
