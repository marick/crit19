defmodule Crit.Setup.AnimalApi do
  use Crit.Global.Constants
  import Pile.Interface
  alias Crit.Setup.AnimalImpl.{Read}
  alias Crit.Setup.Schemas.AnimalOld
  alias Ecto.ChangesetX
  use Crit.Sql.CommonSql, schema: AnimalOld

  def ids_to_animals(ids, institution) do
    ids
    |> some(Read).ids_to_animals(institution)
    |> some(Read).put_updatable_fields(institution)
  end


  def query_by_in_service_date(date, species_id),
    do: Read.Query.available_by_species(date, species_id)

  def ids_to_query(ids),
    do: Read.Query.ids_to_query(ids)
end
