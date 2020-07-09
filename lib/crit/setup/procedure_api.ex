defmodule Crit.Setup.ProcedureApi do
  use Crit.Global.Constants
  alias Crit.Schemas.Procedure
  use Crit.Sql.CommonSql, schema: Procedure
  import Crit.Sql.CommonSql

  def insert(attrs, institution), do: Procedure.insert(attrs, institution)

  deftypical(:all_by_species, :all, [species_id: species_id])
  deftypical(:one_by_id, :one, [id: id])
  def_all_by_Xs(:id)
end
