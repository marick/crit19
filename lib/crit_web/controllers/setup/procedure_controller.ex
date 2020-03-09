defmodule CritWeb.Setup.ProcedureController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :setup_procedure_path
  import CritWeb.Plugs.Authorize
  alias Crit.Setup.{ProcedureApi,InstitutionApi}
  alias CritWeb.ViewModels.Procedure.{Creation,Show}
  alias Ecto.Changeset
  alias Ecto.Multi
  alias Crit.Sql
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
      {:ok, procedures} <- insert_changesets(changesets, institution)
    ) do
      models =
        Enum.map(procedures, &(Show.to_view_model(&1, institution)))
      render(conn, "index.html", procedures: models)
    else
      {:error, changesets} ->
        render_bulk_creation_form(conn, changesets)
    end
  end

  def insert_changesets(changesets, institution) do
    case make_multi(changesets, institution)|> Sql.transaction(institution) do
      {:ok, map} ->
        {:ok, Map.values(map)}
      {:error, {name, _id}, %{errors: [name: {msg, _}]}, _} ->
        index = Enum.find_index(changesets, fn changeset ->
          changeset.changes.name == name
      end)
        updated =
          changesets
          |> List.update_at(index, &(Changeset.add_error(&1, :name, msg)))
        {:error, updated}
    end
  end

  def make_multi(changesets, institution) do
    reducer = fn attrs, multi ->
      Multi.insert(multi,
        {attrs.name, attrs.species_id},
        ProcedureApi.changeset(attrs),
        Sql.multi_opts(institution))
    end

    changesets
    |> Creation.unfold_to_attrs 
    |> Enum.reduce(Multi.new, reducer)
  end


  defp render_bulk_creation_form(conn, changesets) do
    species_pairs = InstitutionApi.available_species(institution(conn))
    
    render(conn, "bulk_creation_form.html",
      changesets: changesets,
      path: path(:bulk_create),
      species_pairs: species_pairs)
  end
end
