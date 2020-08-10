defmodule ListX do

  def delete(list, to_delete),
    do: Enum.reduce(to_delete, list, &(List.delete &2, &1))


  @spec from_namelist(String.t()) :: [String.t()]
  def from_namelist(comma_separated) when is_binary(comma_separated) do
    comma_separated
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn s -> s == "" end)
  end

  def sorted_by_id(container, field) do
    container
    |> Map.get(field)
    |> EnumX.sort_by_id
  end
end
