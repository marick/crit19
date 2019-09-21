defmodule CritWeb.Usables.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :usables_animal_path

  alias Crit.Usables
  alias Crit.Usables.Animal
  alias CritWeb.Audit

  def new(conn, _params) do
    changeset = Usables.animal_creation_changeset(%Animal{})
    render(conn, "new.html",
      changeset: changeset,
      path: path(:create),
      options: Usables.available_species(institution(conn)),
      selected: 0)
  end

  def create(conn, %{"animal" => animal_params}) do
    case Usables.create_animal(animal_params, institution(conn)) do
      {:ok, animals} ->
        conn
        |> Audit.created_animals(animals)
        |> put_flash(:info, "Success!")
        |> render("index.html",
                  animals: animals)
      {:error, %Ecto.Changeset{} = changeset} ->
        render(conn, "new.html", changeset: changeset)
    end
  end
end
