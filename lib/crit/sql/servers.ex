defmodule Crit.Sql.Servers do
  use Agent
  alias Crit.Sql.PrefixServer
  alias Crit.Institutions.Institution
  alias Crit.Repo


  # TODO: make this not depend on Institution

  def start_link(_) do
    institutions = Repo.all(Institution, prefix: "clients")
    servers = Map.new(institutions, &start_one/1)
    Agent.start_link(fn -> servers end, name: __MODULE__)
  end

  def server_for(tag) do
    Agent.get(__MODULE__, &Map.get(&1, tag))
  end

  defp start_one %{short_name: short_name, prefix: prefix} do
    {:ok, pid} = PrefixServer.start_link(prefix)
    {short_name, pid}
  end
end
