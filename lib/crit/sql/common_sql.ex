defmodule Crit.Sql.CommonSql do
  alias Crit.Sql.CommonQuery
  alias Crit.Sql

  def cmd(institution, command, schema, where, opts \\ []) do
    query = CommonQuery.start(schema, where, opts)
    apply(Sql, command, [query, institution])
  end
end
