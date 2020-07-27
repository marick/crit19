defmodule Crit.Params.Builder do
  alias Crit.Params.Get
  # ----------------------------------------------------------------------------

  
  def make_numbered_params(config, descriptors) when is_list(descriptors) do
    descriptors
    |> Enum.map(&(Get.params(config, &1)))
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
end
