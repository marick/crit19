
defmodule Pile.Enum do

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
end
