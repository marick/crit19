defmodule Crit.Sql do
  alias Crit.Sql.Servers

  def insert(struct_or_changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:insert, [struct_or_changeset], opts})
  end

  def one(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:one, [queryable], opts})
  end

end
