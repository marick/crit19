defmodule Crit.Setup.Schemas.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  use Crit.Errors
  alias Ecto.Datespan
  
  schema "service_gaps" do
    field :animal_id, :id
    field :span, Datespan
    field :reason, :string
  end

  def fields, do: __schema__(:fields)
  def required, do: List.delete(fields(), :id)

  def changeset(gap, attrs) do
    gap
    |> cast(attrs, fields())
    |> validate_required(required())
  end
end
