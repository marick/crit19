defmodule Crit.Sql.CommonQuery do
  import Ecto.Query


  def for_name_list(query) do
    query
    |> distinct([x], x.name)
    |> order_by([x], x.name)
  end
end
