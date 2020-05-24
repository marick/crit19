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

  defmacro def_all_by_Xs(column) do
    full_name = "all_by_#{column}s" |> String.to_atom
    quote do
      def unquote(full_name)(desired_ids, institution, opts \\ []) do
        CommonQuery.typical(target_schema(), opts)
        |> where([x], x. unquote(column) in ^desired_ids)
        |> Sql.all(institution)
      end
    end
  end


  defmacro __using__(schema: schema) do
    quote do
      import Ecto.Query
      defp target_schema(), do: unquote(schema)
    end
  end
end
