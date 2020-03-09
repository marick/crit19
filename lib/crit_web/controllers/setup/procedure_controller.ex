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
    case Creation.changesets(Map.values(descriptions)) do
      {:ok, changesets} ->

        result =
          changesets
          |> Creation.unfold_to_attrs 
          |> insert_all__2(institution)

        case result do
          {:ok, stuff} ->
            models =
              Map.values(stuff)
              |> Enum.map(&(Show.to_view_model(&1, institution)))
            render(conn, "index.html", procedures: models)
        end
      {:error, changesets} ->
        render_bulk_creation_form(conn, changesets)
    end
  end

  def insert_all(changesets, institution) do
    changesets
    |> Enum.map(&(ProcedureApi.insert(&1, institution)))
    |> Enum.map(&(elem(&1, 1)))
  end

  def insert_all__2(attr_list, institution) do
    reducer = fn attrs, multi ->
      Multi.insert(multi,
        {attrs.name, attrs.species_id},
        ProcedureApi.changeset(attrs),
        Sql.multi_opts(institution))
    end

    attr_list
    |> Enum.reduce(Multi.new, reducer)
    |> Sql.transaction(institution)
  end

  defp render_bulk_creation_form(conn, changesets) do
    species_pairs = InstitutionApi.available_species(institution(conn))
    
    render(conn, "bulk_creation_form.html",
      changesets: changesets,
      path: path(:bulk_create),
      species_pairs: species_pairs)
  end
end
