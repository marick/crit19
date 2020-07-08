defmodule Crit.Setup.AnimalApiOld do
  use Crit.Global.Constants
  alias Crit.Setup.AnimalImpl.{Read}
  alias Crit.Setup.Schemas.AnimalOld
  use Crit.Sql.CommonSql, schema: AnimalOld

  def query_by_in_service_date(date, species_id),
    do: Read.Query.available_by_species(date, species_id)

  def ids_to_query(ids),
    do: Read.Query.ids_to_query(ids)
end
