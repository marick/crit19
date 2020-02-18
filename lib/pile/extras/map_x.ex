defmodule MapX do

  def just?(map, key) do
    Map.fetch!(map, key) != :nothing
  end

  def just!(map, key) do 
    if just?(map, key) do 
      Map.fetch!(map, key)
    else
      raise("#{inspect map} has a blank key: #{inspect key}")
    end
  end

  # Taken from ex_machina. 
  def convert_atom_keys_to_strings(values) when is_list(values) do
    Enum.map(values, &convert_atom_keys_to_strings/1)
  end

  def convert_atom_keys_to_strings(%{__struct__: _} = record) when is_map(record) do
    Map.from_struct(record) |> convert_atom_keys_to_strings()
  end

  def convert_atom_keys_to_strings(record) when is_map(record) do
    Enum.reduce(record, Map.new(), fn {key, value}, acc ->
      Map.put(acc, to_string(key), convert_atom_keys_to_strings(value))
    end)
  end

  def convert_atom_keys_to_strings(value), do: value
  
end
