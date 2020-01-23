defmodule Crit.Sql do
  alias Crit.Sql.Servers
  alias Crit.Repo
  import Crit.Setup.InstitutionServer, only: [server: 1]

  def all(queryable, opts \\ [], institution) do
    GenServer.call(server(institution),
      {:sql, :all, [queryable], opts})
  end

  def delete_all(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:delete_all, [queryable], opts})
  end

  def exists?(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:exists?, [queryable], opts})
  end

  def get(queryable, id, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:get, [queryable, id], opts})
  end

  def get!(queryable, id, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:get!, [queryable, id], opts})
  end

  def get_by(queryable, clauses, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:get_by, [queryable, clauses], opts})
  end

  def insert(struct_or_changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:insert, [struct_or_changeset], opts})
  end

  def insert!(struct_or_changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:insert!, [struct_or_changeset], opts})
  end

  def insert_all(schema_or_source, entries, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:insert_all, [schema_or_source, entries], opts})
  end

  def one(queryable, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:one, [queryable], opts})
  end

  def update(changeset, opts \\ [], key) do
    server = Servers.server_for(key)
    GenServer.call(server, {:update, [changeset], opts})
  end


  # This may be a decent way of handling institution-specific SQL when institutions
  # have separate databases, not just separate prefixes.

  def multi_opts(key, opts \\ []) do 
    server = Servers.server_for(key)
    GenServer.call(server, {:multi_opts, opts})
  end

  def transaction(multi, _institution) do
    Repo.transaction(multi)
  end
end
