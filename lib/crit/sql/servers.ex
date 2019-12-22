defmodule Crit.Sql.Servers do
  use Agent
  alias Crit.Sql.PrefixServer
  alias Crit.Global

  def start_link(_) do
    institutions = Global.all_institutions()
    IO.inspect institutions
    servers = Map.new(institutions, &start_one/1)
    Agent.start_link(fn -> servers end, name: __MODULE__)
  end

  def server_for(tag) do
    result = Agent.get(__MODULE__, &Map.get(&1, tag))
    if result == nil, do: raise "Bad tag " ++ to_string(tag)
    result
  end

  def put(tag, server) do
    Agent.update(__MODULE__, &Map.put(&1, tag, server))
  end

  def start_one %{short_name: short_name, prefix: prefix} do
    {:ok, pid} = DynamicSupervisor.start_child(Crit.Sql.ServerSupervisor, {PrefixServer, prefix})
    
#    {:ok, pid} = PrefixServer.start_link(prefix)
    {short_name, pid}
  end
end
