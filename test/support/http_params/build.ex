defmodule Crit.Params.Build do
  
  def build(keywords) do
    start = Enum.into(keywords, %{})

    expanded_exemplars =
      Enum.reduce(start.exemplars, %{}, &add_real_exemplar/2)

    Map.put(start, :data, expanded_exemplars)
  end

  def to_strings(map) when is_map(map) do
    map
    |> Enum.map(fn {k,v} -> {to_string(k), to_string_value(v)} end)
    |> Map.new
  end

  defp to_string_value(value) when is_list(value), do: Enum.map(value, &to_string/1)
  defp to_string_value(value) when is_map(value), do: to_strings(value)
  defp to_string_value(value), do: to_string(value)

  def like(valid, except: map) do 
    {:__like, valid, to_strings(map)}
  end

  # ----------------------------------------------------------------------------

  defp add_real_exemplar({new_name, %{params: params} = raw_data}, acc) do
    expanded_params =
      case params do
        {:__like, earlier_name, overriding_params} ->
          Map.merge(acc[earlier_name].params, overriding_params)
        _ ->
          params
      end
    expanded_data = Map.put(raw_data, :params, expanded_params)
    Map.put(acc, new_name, expanded_data)
  end


end

