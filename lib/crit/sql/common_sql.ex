defmodule Crit.Sql.CommonSql do
  alias Crit.Sql.CommonQuery
  alias Crit.Sql

  def typical(institution, command, schema, where, opts \\ []) do
    query = CommonQuery.typical(schema, where, opts)
    apply(Sql, command, [query, institution])
  end

  defmacro deftypical(name, command, [{_field, value}] = where) do
    quote do
      def unquote(name)(unquote(value), institution, opts \\ []) do
        typical(institution, unquote(command), target_schema(), unquote(where), opts)
      end
    end
  end

  defmacro __using__(schema: schema) do
    quote do
      defp target_schema(), do: unquote(schema)
    end
  end
end
