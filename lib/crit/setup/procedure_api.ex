defmodule Crit.Setup.ProcedureApi do
  use Crit.Global.Constants
  alias Crit.Setup.Schemas.{Procedure}

  def insert(attrs, institution), do: Procedure.insert(attrs, institution)
  
  def all_by_species(species_id, institution),
    do: Procedure.all_by([species_id: species_id], institution)
end
