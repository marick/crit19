defmodule Crit.Usables.FieldConverters.ToNameList do
  use Ecto.Schema
  import Ecto.Changeset
  import Crit.Errors
  alias Crit.Ecto.NameList

  # Assumes this partial schema
  #   field :names, :string
  #   field :computed_names, {:array, :string}, virtual: true
  
  def split_names(changeset) do
    names = changeset.changes.names
    case NameList.cast(names) do
      {:ok, []} ->
        add_error(changeset, :names, no_names_error_message())
      {:ok, namelist} -> 
        put_change(changeset, :computed_names, namelist)
      result -> 
        program_error("Namelist cast for `#{names}` is `#{inspect result}`.")
    end
  end

  def no_names_error_message, do: "must have at least one valid name"

end  