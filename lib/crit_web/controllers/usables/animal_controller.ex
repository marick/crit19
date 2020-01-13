defmodule CritWeb.Usables.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :usables_animal_path
  import CritWeb.Plugs.Authorize

  alias Crit.Usables.AnimalApi
  alias CritWeb.Audit
  alias CritWeb.Controller.Common
  
  plug :must_be_able_to, :manage_animals

  defmodule Testable do
    def put_institution(params, institution) do
      add = fn kws ->
        Map.put(kws, "institution", institution)
      end

      top = add.(params)

      case Map.get(top, "service_gaps") do
        nil ->
          top
        gaps ->
          lower = Enum.map(gaps, add)
          Map.put(top, "service_gaps", lower)
      end
    end
  end

  def index(conn, _params) do
    animals = AnimalApi.all(institution(conn))
    render(conn, "index.html", animals: animals)
  end

  def bulk_create_form(conn, _params,
    changeset \\ AnimalApi.bulk_animal_creation_changeset()
  ) do 
    render(conn, "bulk_creation.html",
      changeset: changeset,
      path: path(:bulk_create),
      options: AnimalApi.available_species(institution(conn)))
  end

  def bulk_create(conn, %{"bulk_animal" => raw_params}) do
    params = Testable.put_institution(raw_params, institution(conn))
    case AnimalApi.create_animals(params, institution(conn)) do
      {:ok, animals} ->
        conn
        |> bulk_create_audit(animals, params)
        |> put_flash(:info, "Success!")
        |> render("index.html",
                  animals: animals)
      {:error, %Ecto.Changeset{} = changeset} ->
        bulk_create_form(conn, [], changeset)
    end
  end

  defp bulk_create_audit(conn, animals, params) do
    audit_data = %{ids: EnumX.ids(animals),
                   names: Map.fetch!(params, "names"),
                   put_in_service: Map.fetch!(params, "in_service_datestring"),
                   leaves_service: Map.fetch!(params, "out_of_service_datestring"),
                  }
    Audit.created_animals(conn, audit_data)
  end

  def update_form(conn, %{"animal_id" => id}) do
    animal = AnimalApi.updatable!(id, institution(conn))
    
    Common.render_for_replacement(conn,
      "_edit_one_animal.html",
      changeset: AnimalApi.form_changeset(animal),
      errors: false)
      
  end

  def _show(conn, %{"animal_id" => id}) do
    animal = AnimalApi.updatable!(id, institution(conn))

    Common.render_for_replacement(conn,
      "_show_one_animal.html",
      animal: animal)
  end


  def update(conn, %{"animal_id" => id, "animal" => raw_params}) do
    params =
      raw_params
      |> Common.filter_out_unfilled_subforms("service_gaps",
           ["in_service_datestring", "out_of_service_datestring", "reason"])
      |> Testable.put_institution(institution(conn))

    case AnimalApi.update(id, params, institution(conn)) do
      {:ok, animal} ->
        Common.render_for_replacement(conn,
          "_show_one_animal.html",
          animal: animal)
      {:error, changeset} ->
        conn
        |> Common.render_for_replacement("_edit_one_animal.html",
             changeset: changeset,
             errors: true)
    end
  end
end
