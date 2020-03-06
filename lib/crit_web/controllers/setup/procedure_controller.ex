defmodule CritWeb.Setup.ProcedureController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :setup_procedure_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.{ProcedureApi,InstitutionApi}
  alias CritWeb.ViewModels.Procedure.Creation
  alias Ecto.Changeset
  # alias CritWeb.Audit
  # alias CritWeb.Controller.Common

  IO.puts "Need a new permission"
  plug :must_be_able_to, :manage_animals 

  def bulk_creation_form(conn, _params) do
    species_pairs = InstitutionApi.available_species(institution(conn))
    
    changesets =
      Creation.starting_changeset    
      |> List.duplicate(10)
      |> Enum.with_index
      |> Enum.map(fn {cs, index} -> Changeset.put_change(cs, :index, index) end)
    
    render(conn, "bulk_creation_form.html",
      changesets: changesets,
      path: path(:bulk_create),
      species_pairs: species_pairs)
  end

  def bulk_create(conn, params) do
    IO.inspect params
    conn
  end

end
