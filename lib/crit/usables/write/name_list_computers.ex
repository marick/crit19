defmodule Crit.Usables.Write.NameListComputers do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.NameList

  def split_names(changeset) do
    names = changeset.changes.names
    case NameList.cast(names) do
      {:ok, []} ->
        add_error(changeset, :names, no_names_error_message())
      {:ok, namelist} -> 
        put_change(changeset, :computed_names, namelist)
      _ -> 
        add_error(changeset, :names, impossible_error_message())
    end
  end

  def no_names_error_message, do: "must have at least one valid name"
  def impossible_error_message, do: "has something unexpected wrong with it. Sorry."

end  
