defmodule Crit.Ecto.NameList do
  alias Crit.Ecto.TrimmedString
  
  @behaviour Ecto.Type
  def type, do: {:array, TrimmedString}

  def cast(comma_separated) when is_binary(comma_separated) do
    array = 
      comma_separated
      |> String.split(",")
      |> Enum.map(&TrimmedString.cast/1)
      |> Enum.map(fn {:ok, val} -> val end)
      |> Enum.reject(fn s -> s == "" end)
    {:ok, array}
  end
  def cast(_), do: :error

  # This is only intneded for virtual fields.
  def load(string), do: :error
  def dump(string), do: :error
end
