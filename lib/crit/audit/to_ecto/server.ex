defmodule Crit.Audit.ToEcto.Server do
  use GenServer
  alias Crit.Audit.ToEcto.Record
  alias Crit.Repo
  alias Crit.Audit.LogApi
  @behaviour LogApi

  @impl LogApi
  def put(_pid, %Crit.Audit{} = entry),
    do: GenServer.cast(__MODULE__, {:put, entry})

  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  # Server part

  @impl GenServer
  def init(:ok) do
    {:ok, :no_state}
  end

  @impl GenServer
  def handle_cast({:put, entry}, _no_state) do
    %Record{}
    |> Record.changeset(Map.from_struct(entry))
    |> Repo.insert!
    {:noreply, :no_state}
  end

end



