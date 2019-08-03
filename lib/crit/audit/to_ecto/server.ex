defmodule Crit.Audit.ToEcto.Server do
  use GenServer
  alias Crit.Audit.CreationStruct
  alias Crit.Audit.ToEcto.Record
  alias Crit.Sql

  def put(_pid, %CreationStruct{} = entry, institution),
    do: GenServer.cast(__MODULE__, {:put, entry, institution})

  def start_link(_),
    do: GenServer.start_link(__MODULE__, :ok, name: __MODULE__)

  # Server part

  @impl GenServer
  def init(:ok) do
    {:ok, :no_state}
  end

  @impl GenServer
  def handle_cast({:put, entry, institution}, _no_state) do
    %Record{}
    |> Record.changeset(Map.from_struct(entry))
    |> Sql.insert!(institution)
    {:noreply, :no_state}
  end

end



