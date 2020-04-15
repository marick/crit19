defmodule Crit.Sql.CommonQuery do
  import Ecto.Query

  def start(schema) when is_atom(schema),        do: from x in schema
  def start(schema, where) when is_atom(schema), do: from x in schema, where: ^where

  def ordered_by_name(%Ecto.Query{} = query) do
    query
    |> distinct([x], x.name)
    |> order_by([x], x.name)
  end

  def ordered_by_name(schema) when is_atom(schema) do
    start(schema) |> ordered_by_name
  end

  def narrow_to_ids(query, ids) do
    query |> where([x], x.id in ^ids)
  end

  

  @doc """
  Produces a query that will remove all elements produced by `undesirable`
  from all elements produced by `all`. 
  Uses a left join because Ecto doesn't allow the alternative.
  """
  def subtract(all, undesirable) do
    from a in all,
      left_join: u in subquery(undesirable), on: a.id == u.id,
      where: is_nil(u.name)
  end
end
