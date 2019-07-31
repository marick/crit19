defmodule Crit.Sql do
  use Agent
  alias Crit.Sql.PrefixServer

  def start_link(_) do
    institutions = Application.get_env(:crit, :institutions_in_schemas)
    servers = Map.new(institutions, fn {institution, prefix} ->
      {:ok, pid} = PrefixServer.start_link(prefix)
      {institution, pid}
    end)
    Agent.start_link(fn -> servers end, name: __MODULE__)
  end

  def server_for(institution),
    do: Agent.get(__MODULE__, &Map.get(&1, institution))

  # Server part delegates to a particular server "subclass"

  def insert(struct_or_changeset, opts \\ [], server), 
    do: GenServer.call(server, {:insert, [struct_or_changeset], opts})

end
