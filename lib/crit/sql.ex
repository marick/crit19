defmodule Crit.Sql do
  alias Crit.Repo
  import Crit.Setup.InstitutionServer, only: [server: 1]

  def all(queryable, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :all, [queryable], opts})
  end

  def delete_all(queryable, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :delete_all, [queryable], opts})
  end

  def exists?(queryable, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :exists?, [queryable], opts})
  end

  def get(queryable, id, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :get, [queryable, id], opts})
  end

  def get!(queryable, id, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :get!, [queryable, id], opts})
  end

  def get_by(queryable, clauses, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :get_by, [queryable, clauses], opts})
  end

  def insert(struct_or_changeset, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :insert, [struct_or_changeset], opts})
  end

  def insert!(struct_or_changeset, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :insert!, [struct_or_changeset], opts})
  end

  def insert_all(schema_or_source, entries, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :insert_all, [schema_or_source, entries], opts})
  end

  def one(queryable, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :one, [queryable], opts})
  end

  def update(changeset, opts \\ [], short_name) do
    GenServer.call(server(short_name),
      {:sql, :update, [changeset], opts})
  end


  # This may be a decent way of handling institution-specific SQL when institutions
  # have separate databases, not just separate prefixes.

  def multi_opts(short_name, opts \\ []) do 
    GenServer.call(server(short_name), {:multi_opts, opts})
  end

  # When multiple repos are used, this will need to forward to the
  # `InstitutionServer`.
  def transaction(multi, _short_name) do
    Repo.transaction(multi)
  end
end
