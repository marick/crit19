defmodule CritWeb.Usables.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :usables_animal_path

  alias Crit.Usables
  alias CritWeb.Audit

  def new(conn, _params, changeset \\ Usables.bulk_animal_creation_changeset()) do 
    render(conn, "new.html",
      changeset: changeset,
      path: path(:create),
      options: Usables.available_species(institution(conn)))
  end

  def create(conn, %{"bulk_animal" => animal_params}) do
    case Usables.create_animals(animal_params, institution(conn)) do
      {:ok, animals} ->
        conn
        |> Audit.created_animals(animals)
        |> put_flash(:info, "Success!")
        |> render("index.html",
                  animals: animals)
      {:error, %Ecto.Changeset{} = changeset} ->
        new(conn, [], changeset)
    end
  end
end
