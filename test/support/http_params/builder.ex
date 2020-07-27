defmodule Crit.Params.Builder do
  # ----------------------------------------------------------------------------

  def one_value(config, name), do: config.data[name]
  
  defp exceptions(opts), do: Keyword.get(opts, :except, %{})
  defp deleted_keys(opts), do: Keyword.get(opts, :deleting, [])

  def make_numbered_params(config, descriptors) when is_list(descriptors) do
    descriptors
    |> Enum.map(&(only(config, &1)))
    |> combine_into_numbered_params
  end

  defp combine_into_numbered_params(exemplars) do
    exemplars
    |> Enum.with_index
    |> Enum.map(fn {entry, index} ->
      key = to_string(index)
      value = Map.put(entry, "index", to_string(index))
      {key, value}
    end)
    |> Map.new  
  end

  def only(config, [descriptor | opts]) do
    only(config, descriptor)
    |> Map.merge(exceptions(opts))
    |> Map.drop(deleted_keys(opts))
  end
  
  def only(config, descriptor), do: one_value(config, descriptor).params

end
