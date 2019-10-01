defmodule CritWeb.Usables.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :usables_animal_path
  import CritWeb.Plugs.Authorize

  alias Crit.Usables
  alias CritWeb.Audit

  plug :must_be_able_to, :manage_animals

  def bulk_create_form(conn, _params,
    changeset \\ Usables.bulk_animal_creation_changeset()
  ) do 
    render(conn, "bulk_creation.html",
      changeset: changeset,
      path: path(:bulk_create),
      options: Usables.available_species(institution(conn)))
  end

  def bulk_create(conn, %{"bulk_animal" => animal_params}) do
    case Usables.create_animals(animal_params, institution(conn)) do
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

  def bulk_create_audit(conn, [one_animal | _rest] = animals) do
    audit_data = %{ids: EnumX.ids(animals),
                   in_service_date: one_animal.in_service_date,
                   out_of_service_date: one_animal.out_of_service_date
                  }
    Audit.created_animals(conn, audit_data)
  end
end
