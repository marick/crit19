defmodule CritBiz.Setup.AnimalApi do
  use Crit.Global.Constants
  alias Crit.Schemas.{Animal,ServiceGap}
  use Crit.Sql.CommonSql, schema: Animal
  alias Crit.Sql.CommonQuery
  alias Crit.Sql

  deftypical(:all_by_species, :all, [species_id: species_id])
  deftypical(:one_by_id, :one, [id: id])
  def_all_by_Xs(:id)
  
  # It would be better if we only dealt with animals that are
  # active and in service as of a particular date
  def inadequate_all(institution, opts \\ []) do 
    CommonQuery.typical(target_schema(), opts)
    |> Sql.all(institution)
  end

  def delete_service_gaps(ids, institution) do
    query =
      from s in ServiceGap, where: s.id in ^ids

    expected = length(ids)
    {^expected, _} = Sql.delete_all(query, institution)
  end

  defmodule Query do 
    import Ecto.Query
    import Ecto.Datespan

    def query_by_in_service_date(date, species_id) do
      from a in Animal,
        where: a.species_id == ^species_id,
        where: a.available == true,
        where: contains_point_fragment(a.span, ^date)
    end
    
    def ids_to_query(ids) do
      from a in Animal,
        where: a.id in ^ids
    end
  end
end
