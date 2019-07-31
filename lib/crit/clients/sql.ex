defmodule Crit.Clients.Sql do
  use Agent
  alias Crit.Clients.Sql.PrefixServer
  alias Crit.Clients.Institution
  alias Crit.Repo

  def start_link(_) do
    institutions = Repo.all(Institution, prefix: "clients")
    servers = Map.new(institutions, &start_one/1)
    Agent.start_link(fn -> servers end, name: __MODULE__)
  end

  def server_for(institution) do
    Agent.get(__MODULE__, &Map.get(&1, institution))
  end

  # Server part delegates to a particular server "subclass"

  def insert(struct_or_changeset, opts \\ [], server), 
    do: GenServer.call(server, {:insert, [struct_or_changeset], opts})

    defp start_one %{short_name: short_name, prefix: prefix} do
      {:ok, pid} = PrefixServer.start_link(prefix)
      {short_name, pid}
    end

end
