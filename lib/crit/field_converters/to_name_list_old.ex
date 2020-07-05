defmodule Crit.FieldConverters.ToNameList do
  use Ecto.Schema
  use Crit.Errors
  alias Crit.Errors
  import Ecto.Changeset
  alias Crit.Ecto.NameList

  # Assumes this partial schema
  #   field :names, :string
  #   field :computed_names, {:array, :string}, virtual: true
  
  def split_names(changeset, opts \\ []) do
    %{from: from_field, to: to_field} = Enum.into(opts, %{})
    names = changeset.changes[from_field]
    case NameList.cast(names) do
      {:ok, []} ->
        add_error(changeset, from_field, @no_valid_names_message)
      {:ok, namelist} -> 
        put_change(changeset, to_field, namelist)
      result -> 
        Errors.program_error("Namelist cast for `#{names}` is `#{inspect result}`.")
    end
  end
end  
