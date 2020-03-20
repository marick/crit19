defmodule EnumX do

  @doc """
      iex> Pile.Enum.extract([1, 2, 3], fn x -> x == 2 end)
      {2, [1, 3]}

  The function must match exactly one time.
  """
  def extract(list, f) do
    grouped = Enum.group_by(list, f)
    [elt] = Map.get(grouped, true)
    others = Map.get(grouped, false, [])
    {elt, others}
  end

  def sort_by_id(structs) do
    Enum.sort_by(structs, &(&1.id))
  end

  def ids(structs) do
    structs
    |> Enum.map(&(&1.id))
    |> Enum.sort
  end

  def names(named), do: Enum.map(named, &(&1.name))

  def all_empty?(list_of_enums),
    do: Enum.all?(list_of_enums, &Enum.empty?/1)

  def pairs(maps, first, second),
    do: Enum.map(maps, &({Map.fetch!(&1, first), Map.fetch!(&1, second)}))

  def id_pairs(maps, other), do: pairs(maps, other, :id)

  def find_by_id(maps, id), 
    do: Enum.find(maps, fn one -> one.id == id end)

  def to_id_map(maps, value_key) do
    maps 
    |> pairs(:id, value_key)
    |> Map.new
  end
end
