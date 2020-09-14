defmodule CritWeb.Setup.AnimalController do
  use CritWeb, :controller
  use CritWeb.Controller.Path, :setup_animal_path
  import CritWeb.Plugs.Authorize

  alias Crit.Servers.Institution
  alias CritWeb.Audit
  alias CritWeb.Controller.Common
  alias CritBiz.ViewModels.Setup, as: VM
  alias Ecto.ChangesetX
  alias Ecto.Changeset
  alias CritWeb.Setup.AnimalController.Testable   # Local
  
  plug :must_be_able_to, :manage_animals

  def index(conn, _params) do
    institution = institution(conn)
    animals = VM.Animal.fetch(:all_possible, institution)
    render(conn, "index.html", animals: animals)
  end

  def _show(conn, %{"animal_id" => id}) do
    institution = institution(conn)
    animal = VM.Animal.fetch(:one_for_summary, id, institution)
    Common.render_for_replacement(conn,
      "_show_one_animal.html",
      animal: animal)
  end

  # ----------------------------------------------------------------------------
  def bulk_create_form(conn, _params),
    do: render_bulk_create_form(conn, VM.BulkAnimal.fresh_form_changeset())

  def bulk_create(conn, %{"bulk_animal" => params}) do
    inst = institution(conn)
    with(
      {:ok, vm_changeset} <- VM.BulkAnimal.accept_form(params, inst),
      proposed_animals = VM.BulkAnimal.lower_changeset(vm_changeset),
      {:ok, vm_animals} <- VM.BulkAnimal.insert_all(proposed_animals, inst)
    ) do
        conn
        |> bulk_create_audit(vm_animals, params)
        |> put_flash(:info, "Success!")
        |> render("index.html", animals: vm_animals)
    else
      {:error, :form, vm_changeset} ->
        render_bulk_create_form(conn, vm_changeset)
      {:error, :constraint, %{message: message}} ->
        # vm_changeset from above is not in scope. Blah.
        {:ok, vm_changeset} = VM.BulkAnimal.accept_form(params, inst)
        render_bulk_create_form(
          conn,
          ChangesetX.add_as_visible_error(vm_changeset, :names, message))
    end
  end

  # ----------------------------------------------------------------------------
  def update_form(conn, %{"animal_id" => id}) do
    institution = institution(conn)
    animal = VM.Animal.fetch(:one_for_edit, id, institution)
    
    Common.render_for_replacement(conn,
      "_edit_one_animal.html",
      path: path(:update, animal.id),
      changeset: VM.Animal.fresh_form_changeset(animal),
      errors: false)
  end

  def update(conn, %{"animal_old_id" => id, "animal" => params}) do
    inst = institution(conn)
    with(
      {:ok, vm_changeset} <- VM.Animal.accept_form(params, inst),
      repo_changeset = VM.Animal.lower_changeset(vm_changeset, id, inst),
      {:ok, animal} <- VM.Animal.update(repo_changeset, inst)
    ) do
      Common.render_for_replacement(conn,
        "_show_one_animal.html",
        animal: animal)
    else
      {:error, :form, vm_changeset} ->
        render_edit_form(conn, id, vm_changeset)
        
      {:error, :constraint, schema_changeset} ->
        # vm_changeset from above is not in scope. Blah.
        {:ok, original_vm_changeset} = VM.Animal.accept_form(params, inst)
              
        vm_changeset_with_errors =
          ChangesetX.merge_only_errors(original_vm_changeset, schema_changeset)

        render_edit_form(conn, id, vm_changeset_with_errors)
        
      {:error, :optimistic_lock, id} ->
        new_changeset = 
          VM.Animal.fetch(:one_for_edit, id, inst)
          |> VM.Animal.fresh_form_changeset
          |> Changeset.add_error(:optimistic_lock_error, @animal_optimistic_lock)
          |> ChangesetX.ensure_forms_display_errors

        render_edit_form(conn, id, new_changeset)
    end
  end

  # ----------------------------------------------------------------------------

  defp render_bulk_create_form(conn, changeset) do 
    render(conn, "bulk_creation.html",
      changeset: changeset,
      path: path(:bulk_create))
  end

  defp render_edit_form(conn, id, changeset) do 
    Common.render_for_replacement(conn,
      "_edit_one_animal.html",
      path: path(:update, id),
      changeset: changeset,
      errors: not changeset.valid?)
  end
  
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
  
  # ----------------------------------------------------------------------------

  defp bulk_create_audit(conn, animals, params) do
    audit_data = %{ids: EnumX.ids(animals),
                   names: Map.fetch!(params, "names"),
                   put_in_service: Map.fetch!(params, "in_service_datestring"),
                   leaves_service: Map.fetch!(params, "out_of_service_datestring"),
                  }
    Audit.created_animals(conn, audit_data)
  end
end
