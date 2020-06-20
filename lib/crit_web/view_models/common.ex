defmodule CritWeb.ViewModels.Common do
  def flatten(params, name) do
    params
    |> Map.put(name, Map.values(params[name]))
  end
end
