defmodule Crit.Sql.Servers do
  use GenServer
  alias Crit.Sql.PrefixServer
  alias Crit.Global
  require Logger

  def start_link(opts) do
    GenServer.start_link(__MODULE__, :ok, opts)
  end

  def server_for(tag),
    do: GenServer.call(__MODULE__, {:server_for, tag})
  
  # Server part

  @impl GenServer
  def init(_) do
    institutions = Global.all_institutions()
    servers = Map.new(institutions, &start_one/1)
    {:ok, servers}
  end

  defp start_one %{short_name: short_name, prefix: prefix} do
    Logger.info "Starting prefix server: #{inspect [short_name, prefix]}"
    {:ok, pid} = PrefixServer.start_link(prefix)
    {short_name, pid}
  end

  @impl GenServer
  def handle_call({:server_for, tag}, _from, servers) do
    result = Map.get(servers, tag)
    if result == nil, do: raise "Bad tag " ++ to_string(tag)
    {:reply, result, servers}
  end
end
