defmodule Crit.Sql do
  alias Crit.Repo
  import Crit.Setup.InstitutionServer, only: [server: 1]

  @moduledoc """
  These functions use the Institution's shortname to send the right
  SQL to the right place. 

  There's an function for each `Ecto.Repo` function (that is used by
  this application). Each works by asking the `InstitutionServer` to
  provide arguments for it to `apply`. The caller does the work
  because otherwise tests would have to arrange for the
  `InstitutionServer` and the test to share the same `SQL.Sandbox`
  connection, which is awkward because the `InstitutionServer` is by
  default started before any test setup runs.

  For probably no good reason, `Ecto.Multi` functions are called
  directly, except that `multi_opts` is used to rewrite their options
  to an apropriate form, then `Sql.transaction` makes sure the right
  `Ecto.Repo` is used.

  2020/18/03
  """

  def all(queryable, opts \\ [], short_name) do
    run_modified(short_name, :all, {[queryable], opts})
  end

  def delete_all(queryable, opts \\ [], short_name) do
    run_modified(short_name, :delete_all, {[queryable], opts})
  end

  def exists?(queryable, opts \\ [], short_name) do
    run_modified(short_name, :exists?, {[queryable], opts})
  end

  def get(queryable, id, opts \\ [], short_name) do
    run_modified(short_name, :get, {[queryable, id], opts}) end

  def get!(queryable, id, opts \\ [], short_name) do
    run_modified(short_name, :get!, {[queryable, id], opts}) end

  def get_by(queryable, clauses, opts \\ [], short_name) do
    run_modified(short_name, :get_by, {[queryable, clauses], opts})
  end

  def insert(struct_or_changeset, opts \\ [], short_name) do
    run_modified(short_name, :insert, {[struct_or_changeset], opts})
  end

  def insert!(struct_or_changeset, opts \\ [], short_name) do
    run_modified(short_name, :insert!, {[struct_or_changeset], opts})
  end

  def insert_all(schema_or_source, entries, opts \\ [], short_name) do
    run_modified(short_name, :insert_all, {[schema_or_source, entries], opts})
  end

  def one(queryable, opts \\ [], short_name) do
    run_modified(short_name, :one, {[queryable], opts})
  end

  def update(changeset, opts \\ [], short_name) do
    run_modified(short_name, :update, {[changeset], opts}) end

  defp run_modified(short_name, sql_command, data_for_server) do
    command = Tuple.insert_at(data_for_server, 0, :adjust)
    [repo, arglist] = 
      GenServer.call(server(short_name), command)

    apply(repo, sql_command, arglist)
  end

  # ------------------------------------------------------------------------


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
