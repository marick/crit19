defmodule CritWeb.Usables.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :usables_animal_path
  import CritWeb.Plugs.Authorize

  alias Crit.Usables.AnimalApi
  alias CritWeb.Audit
  
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
        |> bulk_create_audit(animals)
        |> put_flash(:info, "Success!")
        |> render("index.html",
                  animals: animals)
      {:error, %Ecto.Changeset{} = changeset} ->
        bulk_create_form(conn, [], changeset)
    end
  end

  defp bulk_create_audit(conn, [one_animal | _rest] = animals) do
    audit_data = %{ids: EnumX.ids(animals),
                   in_service_date: one_animal.in_service_date,
                   out_of_service_date: one_animal.out_of_service_date
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
    simplified_params = remove_empty_sub_forms(animal_params)
    case AnimalApi.update(id, simplified_params, institution(conn)) do
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

  def remove_empty_sub_forms(animal_params) do
    trimmed = fn string ->
      string |> String.trim_leading |> String.trim_trailing
    end

    empty_form? = fn sg ->
      fields = 
        ["in_service_date", "out_of_service_date", "reason"]

      Enum.all?(fields, &(trimmed.(sg[&1]) == ""))
    end

    simplified = 
      animal_params
      |> Map.get("service_gaps")
      |> Map.values
      |> Enum.reject(empty_form?)

    Map.put(animal_params, "service_gaps", simplified)
  end
end
