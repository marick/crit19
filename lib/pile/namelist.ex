defmodule Pile.Namelist do
  alias Ecto.Changeset
  use Crit.Errors
  

  @type t() :: String.t

  @spec to_list(t()) :: [String.t()]
  def to_list(comma_separated) when is_binary(comma_separated) do
    comma_separated
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(fn s -> s == "" end)
  end

end
