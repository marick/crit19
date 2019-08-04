defmodule Crit.Sql do
  alias Crit.Sql.Servers
  alias Crit.Sql.Api

  @behaviour Api

  @impl true
  def all(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:all, [queryable], opts})
  end

  @impl true
  def delete_all(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:delete_all, [queryable], opts})
  end

  @impl true
  def exists?(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:exists?, [queryable], opts})
  end

  @impl true
  def get(queryable, id, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:get, [queryable, id], opts})
  end

  @impl true
  def get_by(queryable, clauses, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:get_by, [queryable, clauses], opts})
  end

  @impl true
  def insert(struct_or_changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:insert, [struct_or_changeset], opts})
  end

  @impl true
  def insert!(struct_or_changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:insert!, [struct_or_changeset], opts})
  end

  @impl true
  def one(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:one, [queryable], opts})
  end

  @impl true
  def update(changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:update, [changeset], opts})
  end
end
