defmodule Crit.Ecto.TrimmedString do
  @behaviour Ecto.Type
  def type, do: :string

  def cast(possibly_untrimmed) when is_binary(possibly_untrimmed), 
    do: {:ok, String.trim(possibly_untrimmed)}
  def cast(_), do: :error

  def load(string), do: {:ok, string}
  def dump(string), do: {:ok, string}
end
