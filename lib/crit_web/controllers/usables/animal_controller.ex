defmodule CritWeb.Usables.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :usables_animal_path
  import CritWeb.Plugs.Authorize

  alias Crit.Usables.AnimalApi
  alias CritWeb.Audit
  alias CritWeb.Controller.Common
  
  plug :must_be_able_to, :manage_animals

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

  def bulk_create(conn, %{"bulk_animal" => animal_params}) do
    case AnimalApi.create_animals(animal_params, institution(conn)) do
      {:ok, animals} ->
        conn
        |> bulk_create_audit(animals, animal_params)
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
    
    conn
    |> put_layout(false)
    |> render("_edit_one_animal.html",
        changeset: AnimalApi.form_changeset(animal))
  end
  
  def update(conn, %{"animal_id" => id, "animal" => animal_params}) do
    params =
      Common.filter_out_unfilled_subforms(animal_params, "service_gaps",
        ["in_service_date", "out_of_service_date", "reason"])
    case AnimalApi.update(id, params, institution(conn)) do
      {:ok, animal} ->
        Common.render_for_replacement(conn,
          "_show_one_animal.html",
          changeset: AnimalApi.form_changeset(animal),
          highlight: "has-background-grey-lighter")
      {:error, changeset} ->
        Common.render_for_replacement(conn,
          "_edit_one_animal.html",
          changeset: changeset)
    end
  end
end
