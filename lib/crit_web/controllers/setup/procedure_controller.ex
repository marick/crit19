defmodule CritWeb.Setup.ProcedureController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :setup_procedure_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.InstitutionApi
  alias CritBiz.ViewModels.Setup, as: VM
  alias Ecto.ChangesetX

  IO.puts "Need a new permission"
  plug :must_be_able_to, :manage_animals 

  def bulk_creation_form(conn, _params) do
    changesets = VM.BulkProcedure.fresh_form_changesets()
    render_bulk_creation_form(conn, changesets)
  end
  
  def bulk_create(conn, %{"procedures" => params}) do
    institution = institution(conn)
    with(
      {:ok, vm_changesets} <- VM.BulkProcedure.accept_form(params),
      procedures = VM.BulkProcedure.lower_changesets(vm_changesets),
      {:ok, vm_procedures} <- VM.BulkProcedure.insert_all(procedures, institution)
    ) do
      render(conn, "index.html", procedures: vm_procedures)
    else
      {:error, :form, changesets} ->
        render_bulk_creation_form(conn, changesets)
      {:error, :constraint, %{duplicate_name: index, message: message}} ->
        changesets = 
          # vm_changeset from above is not in scope. Blah.
          VM.BulkProcedure.accept_form(params)
          |> elem(1)
          |> List.update_at(index, fn changeset ->
               ChangesetX.add_as_visible_error(changeset, :name, message)
             end)
        render_bulk_creation_form(conn, changesets)
    end
  end

  # ------------------------------------------------------------------------

  defp render_bulk_creation_form(conn, changesets) do
    species_pairs = InstitutionApi.species(institution(conn)) |> EnumX.id_pairs(:name)
    frequencies = InstitutionApi.procedure_frequencies(institution(conn))
    render(conn, "bulk_creation_form.html",
      changesets: changesets,
      path: path(:bulk_create),
      species_pairs: species_pairs,
      frequencies: frequencies)
  end
end
