defmodule Crit.Sql.CommonSql do
  alias Crit.Sql.CommonQuery
  alias Crit.Sql

  def typical(institution, command, schema, where, opts \\ []) do
    query = CommonQuery.typical(schema, where, opts)
    apply(Sql, command, [query, institution])
  end

  defmacro deftypical(name, command, schema, [{_field, value}] = where) do
    quote do
      def unquote(name)(unquote(value), institution, opts \\ []) do
        typical(institution, unquote(command), unquote(schema), unquote(where), opts)
      end
    end
  end
end
