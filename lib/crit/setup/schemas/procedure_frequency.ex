defmodule Crit.Setup.Schemas.ProcedureFrequency do
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString

  schema "procedure_frequencies" do
    field :name, TrimmedString
    field :calculation_name, TrimmedString
    field :description, :string, default: ""
  end
end
