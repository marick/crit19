defmodule CritWeb.Setup.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :setup_animal_path
  import CritWeb.Plugs.Authorize

  alias Crit.Setup.{AnimalApi,InstitutionApi}
  alias CritWeb.Audit
  alias CritWeb.Controller.Common
  alias CritWeb.ViewModels.Setup, as: VM
  
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
          lower = 
            gaps
            |> Enum.map(fn {key, gap} -> { key, add.(gap) } end)
            |> Map.new
          Map.put(top, "service_gaps", lower)
      end
    end
  end

  def index(conn, _params) do
    institution = institution(conn)
    animals = VM.Animal.fetch(:all_possible, institution)
    render(conn, "index.html", animals: animals)
  end

  def bulk_create_form(conn, _params,
    changeset \\ AnimalApi.bulk_animal_creation_changeset()
  ) do 
    render(conn, "bulk_creation.html",
      changeset: changeset,
      path: path(:bulk_create),
      options: InstitutionApi.species(institution(conn)) |> EnumX.id_pairs(:name))
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
    institution = institution(conn)
    animal = VM.Animal.fetch(:one_for_edit, id, institution)
    
    Common.render_for_replacement(conn,
      "_edit_one_animal.html",
      path: path(:update, animal.id),
      changeset: AnimalApi.form_changeset(animal),
      errors: false)
      
  end

  def _show(conn, %{"animal_id" => id}) do
    institution = institution(conn)
    animal = VM.Animal.fetch(:one_for_summary, id, institution)
    Common.render_for_replacement(conn,
      "_show_one_animal.html",
      animal: animal)
  end

  def update(conn, %{"animal_old_id" => id, "animal" => params}) do
    inst = institution(conn)
    with(
      {:ok, upward_changeset} <- VM.Animal.accept_form(params, inst),
      downward_changeset = VM.Animal.prepare_for_storage(id, upward_changeset),
      {:ok, animal} <- VM.Animal.update(downward_changeset, inst)
    ) do
      Common.render_for_replacement(conn,
        "_show_one_animal.html",
        animal: animal)
    end
      

    # case changeset.valid? do
    #   true ->
    #     downward_params =
    #       VM.Animal.update_params(changeset)
    #     current =
    #       AnimalApi2.one_by_id(id, institution(conn), preload: [:species, :service_gaps])

    #     deletable? = fn cs ->
    #       Changeset.get_change(cs, :delete) == true
    #     end
        
    #     {:ok, _} = 
    #       Changeset.change(current, downward_params)
    #       |> IO.inspect
    #       |> Sql.update(institution(conn))

    #     Changeset.get_change(changeset, :service_gaps)
    #     |> Enum.filter(deletable?)
    #     |> Enum.map(&(Changeset.get_field(&1, :id)))
    #     |> AnimalApi2.delete_service_gaps(institution(conn))
        
    #   false -> 
    #     IO.inspect "skip"
    # end

    # case AnimalApi.update(id, params, institution(conn)) do
    #   {:ok, animal} ->
    #     Common.render_for_replacement(conn,
    #       "_show_one_animal.html",
    #       animal: animal)
    #   {:error, changeset} ->
    #     conn
    #     |> Common.render_for_replacement("_edit_one_animal.html",
    #          changeset: changeset,
  #          errors: true)
  end
end
