defmodule Crit.Audit.ToMemory.Server do
  use GenServer
  alias Crit.Audit.CreationStruct

  def put(pid, %CreationStruct{} = entry, institution),
    do: GenServer.call(pid, {:put, entry, institution})

  def latest(pid), do: GenServer.call(pid, :latest)

  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok)

  # Server part

  @impl GenServer
  def init(:ok) do
    {:ok, []}
  end

  @impl GenServer
  def handle_call({:put, entry, _institution}, _from, state) do
    {:reply, :ok, [entry | state]}
  end

  @impl GenServer
  def handle_call(:latest, _from, state) do
    {:reply, {:ok, List.first(state)}, state}
  end    

end
