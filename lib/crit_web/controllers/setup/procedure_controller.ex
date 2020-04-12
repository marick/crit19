defmodule CritWeb.Setup.ProcedureController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :setup_procedure_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.InstitutionApi
  alias CritWeb.ViewModels.Procedure.{Creation,Show}
  alias Ecto.Changeset
  # alias CritWeb.Audit
  # alias CritWeb.Controller.Common

  IO.puts "Need a new permission"
  plug :must_be_able_to, :manage_animals 

  def bulk_creation_form(conn, _params) do
    changesets =
      Creation.starting_changeset    
      |> List.duplicate(10)
      |> Enum.with_index
      |> Enum.map(fn {cs, index} -> Changeset.put_change(cs, :index, index) end)

    render_bulk_creation_form(conn, changesets)
  end

  def bulk_create(conn, %{"procedures" => descriptions}) do
    institution = institution(conn)
    with(
      {:ok, changesets} <- Creation.changesets(Map.values(descriptions)),
      {:ok, procedures} <- Creation.insert_changesets(changesets, institution)
    ) do
      models =
        Enum.map(procedures, &(Show.to_view_model(&1, institution)))
      render(conn, "index.html", procedures: models)
    else
      {:error, changesets} ->
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
