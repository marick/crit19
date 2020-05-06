defmodule Crit.Setup.ProcedureApi do
  use Crit.Global.Constants
  alias Crit.Setup.Schemas.Procedure
  import Crit.Sql.CommonSql

  def insert(attrs, institution), do: Procedure.insert(attrs, institution)
  def changeset(attrs), do: Procedure.changeset(%Procedure{}, attrs)

  deftypical(:all_by_species, :all, Procedure, [species_id: species_id])
  deftypical(:one_by_id, :one, Procedure, [id: id])
end
