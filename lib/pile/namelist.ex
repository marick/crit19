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

  def validate(changeset, field) do
    string = Changeset.get_change(changeset, field, "")
    case to_list(string) do
      [] -> 
        Changeset.add_error(changeset, field, @no_valid_names_message)
      list ->
        if EnumX.has_duplicates?(list) do
          Changeset.add_error(changeset, field, @duplicate_name)
        else
          changeset
        end
    end
  end
end
