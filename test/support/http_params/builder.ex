defmodule Crit.Params.Builder do

  # convert shorthand into the kind of parameters delivered to
  # controller actions.
  
  def to_strings(map) when is_map(map) do
    map
    |> Enum.map(fn {k,v} -> {to_string(k), to_string_value(v)} end)
    |> Map.new
  end

  defp to_string_value(value) when is_list(value), do: Enum.map(value, &to_string/1)
  defp to_string_value(value) when is_map(value), do: to_strings(value)
  defp to_string_value(value), do: to_string(value)


  def build(keywords) do
    start = Enum.into(keywords, %{})

    expanded_exemplars =
      Enum.reduce(start.exemplars, %{}, &add_real_exemplar/2)

    Map.put(start, :data, expanded_exemplars)
  end


  defp add_real_exemplar({new_name, %{params: params} = raw_data} = tuple, acc) do
    expanded_params =
      case params do
        {:__like, earlier_name, overriding_params} ->
          IO.inspect earlier_name
          IO.inspect acc
          Map.merge(acc[earlier_name].params, overriding_params)
        _ ->
          params
      end
    expanded_data = Map.put(raw_data, :params, expanded_params) |> IO.inspect(label: "expanded")
    Map.put(acc, new_name, expanded_data) |> IO.inspect
  end


  def like(valid, except: map) do 
    {:__like, valid, to_strings(map)}
  end

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


  # ----------------------------------------------------------------------------

  def __using__(_) do 
  end
end
