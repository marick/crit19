defmodule Crit.Sql do
  alias Crit.Sql.Servers
  alias Crit.Sql.Api

  @behaviour Api

  @impl Api
  def insert(struct_or_changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:insert, [struct_or_changeset], opts})
  end

  @impl Api
  def one(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:one, [queryable], opts})
  end

  @impl Api
  def get(queryable, id, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:get, [queryable, id], opts})
  end

  @impl Api
  def get_by(queryable, clauses, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:get_by, [queryable, clauses], opts})
  end

  @impl Api
  def update(changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:update, [changeset], opts})
  end

end
