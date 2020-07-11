defmodule CritWeb.Setup.ProcedureController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :setup_procedure_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.InstitutionApi
  alias CritBiz.ViewModels.Setup, as: VM
  alias Ecto.Changeset

  IO.puts "Need a new permission"
  plug :must_be_able_to, :manage_animals 

  def bulk_creation_form(conn, _params) do
    changesets = VM.BulkProcedure.fresh_form_changesets()
    render_bulk_creation_form(conn, changesets)
  end

  def bulk_create(conn, %{"procedures" => descriptions}) do
    institution = institution(conn)
    with(
      {:ok, changesets} <- VM.BulkProcedure.changesets(Map.values(descriptions)),
      {:ok, procedures} <- VM.BulkProcedure.insert_changesets(changesets, institution)
    ) do
      models =
        Enum.map(procedures, &(VM.Procedure.to_view_model(&1, institution)))
      render(conn, "index.html", procedures: models)
    else
      {:error, changesets} ->
        render_bulk_creation_form(conn, changesets)
    end
  end

  # def bulk_create__2(conn, %{"procedures" => params}) do
  #   institution = institution(conn)
  #   with(
  #     {:ok, vm_changesets} <- VM.BulkProcedure.accept_form(params),
  #     proposed_procedures = VM.BulkProcedure.lower_changesets(vm_changeset),
  #     {:ok, vm_procedures} <- VM.BulkProcedure.insert_all(changesets, institution)
  #   ) do
  #     render(conn, "index.html", procedures: vm_procedures)
  #   else
  #     {:error, :form, changesets} ->
  #       render_bulk_creation_form(conn, changesets)
  #     {:error, :constraint, %{duplicate_name: name} ->
  #       # vm_changeset from above is not in scope. Blah.
  #       {:ok, vm_changeset} = VM.BulkProcedures.accept_form(params)
  #       message = ~s[A procedure named "#{name}" already exists for <<<species>>>]
  #       render_bulk_create_form(
  #         conn,
  #         ChangesetX.add_as_visible_error(vm_changeset, :names, message))
  #     end
  #   end
  # end

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
