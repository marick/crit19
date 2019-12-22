defmodule Crit.Sql.Servers do
  use GenServer
  alias Crit.Sql.PrefixServer
  alias Crit.Global

  def start_link(opts) do
    IO.inspect opts, label: "start link"
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def server_for(tag),
    do: GenServer.call(__MODULE__, {:server_for, tag})
  
  # Server part

  @impl GenServer
  def init(_) do
    institutions = Global.all_institutions()
    IO.inspect institutions, label: "institutions"
    servers = Map.new(institutions, &start_one/1)
    IO.inspect servers
    IO.inspect self()
    {:ok, servers}
  end

  defp start_one %{short_name: short_name, prefix: prefix} do
#    {:ok, pid} = DynamicSupervisor.start_child(Crit.Sql.ServerSupervisor, {PrefixServer, prefix})

    IO.inspect {short_name, prefix}
    {:ok, pid} = PrefixServer.start_link(prefix)
    IO.inspect pid
    {short_name, pid}
  end

  @impl GenServer
  def handle_call({:server_for, tag}, _from, servers) do
    result = Map.get(servers, tag)
    if result == nil, do: raise "Bad tag " ++ to_string(tag)
    {:reply, result, servers}
  end
end
