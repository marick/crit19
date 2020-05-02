defmodule Crit.Setup.ProcedureApi do
  use Crit.Global.Constants
  alias Crit.Setup.Schemas.{Procedure}
  alias Crit.Sql
  alias Crit.Sql.CommonQuery
  import Ecto.Query

  def insert(attrs, institution), do: Procedure.insert(attrs, institution)
  
  def all_by_species(species_id, institution),
    do: CommonQuery.start(Procedure, [species_id: species_id]) |> Sql.all(institution)

  def changeset(attrs), do: Procedure.changeset(%Procedure{}, attrs)

  def one_by_id(id, opts \\ [], institution) do
    CommonQuery.start(Procedure, [id: id], opts) |> Sql.one(institution)
  end
end
