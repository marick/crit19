defmodule ListX do

  def delete(list, to_delete),
    do: Enum.reduce(to_delete, list, &(List.delete &2, &1))
end
