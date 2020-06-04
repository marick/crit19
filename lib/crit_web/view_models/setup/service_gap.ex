defmodule CritWeb.ViewModels.Setup.ServiceGap do
  use Ecto.Schema
  # import Ecto.Changeset
  # alias Ecto.Datespan
  # use Crit.Errors
  # alias Crit.FieldConverters.ToSpan
  # alias Crit.FieldConverters.FromSpan
  # import Ecto.Query
  # import Ecto.Datespan
  # alias Crit.Sql
  # alias Crit.Sql.CommonQuery
  
  @primary_key false   # I do this to emphasize that ID not be forgotten.
  embedded_schema do
    field :id, :id
    field :reason, :string

    field :institution, :string, virtual: true 
    field :in_service_datestring, :string, virtual: true
    field :out_of_service_datestring, :string, virtual: true
    field :delete, :boolean, default: false, virtual: true
  end
end
