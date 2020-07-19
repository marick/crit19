defmodule Crit.Params do
  @moduledoc """
  Shorthand map functions for use in tests.
  """

  # convert shorthand into the kind of parameters delivered to
  # controller actions.
  
  def paramify(map) when is_map(map) do
    map
    |> Enum.map(fn {k,v} -> {to_string(k), paramify_value(v)} end)
    |> Map.new
  end

  defp paramify_value(value) when is_list(value), do: Enum.map(value, &to_string/1)
  defp paramify_value(value) when is_map(value), do: paramify(value)
  defp paramify_value(value), do: to_string(value)
end
