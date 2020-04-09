defmodule Crit.Setup.HiddenSchemas.ProcedureFrequency do
  use Ecto.Schema
#  import Ecto.Changeset
  alias Crit.Ecto.TrimmedString

  schema "procedure_frequencies" do
    field :name, TrimmedString
    field :calculation_name, TrimmedString
    field :description, :string, default: ""
  end
end
