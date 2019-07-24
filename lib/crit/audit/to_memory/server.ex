defmodule Crit.Audit.ToMemory.Server do
  use GenServer
  alias Crit.Audit.LogApi
  @behaviour LogApi

  @impl LogApi
  def put(pid, %Crit.Audit{} = entry),
    do: GenServer.call(pid, {:put, entry})

  def latest(pid), do: GenServer.call(pid, :latest)

  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok)

  # Server part

  @impl GenServer
  def init(:ok) do
    {:ok, []}
  end

  @impl GenServer
  def handle_call({:put, entry}, _from, state) do
    {:reply, :ok, [entry | state]}
  end

  @impl GenServer
  def handle_call(:latest, _from, state) do
    {:reply, {:ok, List.first(state)}, state}
  end    

end
