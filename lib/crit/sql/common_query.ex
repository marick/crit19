defmodule Crit.Sql.CommonQuery do
  import Ecto.Query

  def for_name_list(query) do
    query
    |> distinct([x], x.name)
    |> order_by([x], x.name)
  end

  def ordered_by_name(schema) do
    (from x in schema) |> for_name_list
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
