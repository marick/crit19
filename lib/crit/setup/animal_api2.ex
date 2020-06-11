defmodule Crit.Setup.AnimalApi2 do
  use Crit.Global.Constants
#  import Pile.Interface
  # alias Crit.Setup.AnimalImpl.{BulkCreationTransaction,Write, Read}
#  alias CritWeb.ViewModels.Setup.BulkAnimal
  alias Crit.Setup.Schemas.Animal
#  alias Ecto.ChangesetX
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
end
