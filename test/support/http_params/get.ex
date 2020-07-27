defmodule Crit.Params.Get do
  def exemplar(config, name), do: config.exemplars[name]

  def params(config, [descriptor | opts]) do
    params(config, descriptor)
    |> Map.merge(exceptions(opts))
    |> Map.drop(deleted_keys(opts))
  end
  
  def params(config, descriptor), do: exemplar(config, descriptor).params


  # ----------------------------------------------------------------------------
  defp exceptions(opts), do: Keyword.get(opts, :except, %{})
  defp deleted_keys(opts), do: Keyword.get(opts, :deleting, [])
end
