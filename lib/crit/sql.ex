defmodule Crit.Sql do
  alias Crit.Sql.Servers

  def insert(struct_or_changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:insert, [struct_or_changeset], opts})
  end
end
