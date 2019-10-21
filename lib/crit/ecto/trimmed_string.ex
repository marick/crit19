defmodule Crit.Ecto.TrimmedString do
  use Ecto.Type
  
  @impl Ecto.Type
  def type, do: :string

  @impl Ecto.Type
  def cast(possibly_untrimmed) when is_binary(possibly_untrimmed), 
    do: {:ok, String.trim(possibly_untrimmed)}
  def cast(_), do: :error

  @impl Ecto.Type
  def load(string), do: {:ok, string}
  @impl Ecto.Type
  def dump(string), do: {:ok, string}
end
