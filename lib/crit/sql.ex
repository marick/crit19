defmodule Crit.Sql do
  use Agent

  def start_link(servers),
    do: Agent.start_link(fn -> servers end, name: __MODULE__)

  def server_for(institution),
    do: Agent.get(__MODULE__, &Map.get(&1, institution))

  # Server part delegates to a particular server "subclass"

  def insert(struct_or_changeset, opts \\ [], server), 
    do: GenServer.call(server, {:insert, [struct_or_changeset], opts})

end
