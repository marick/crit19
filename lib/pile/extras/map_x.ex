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
end
