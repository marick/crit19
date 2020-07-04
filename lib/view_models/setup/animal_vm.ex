defmodule CritBiz.ViewModels.Setup.Animal do
  use CritWeb, :view_model
  alias CritBiz.ViewModels.Setup, as: VM
  import CritBiz.ViewModels.Common, only: [flatten_numbered_sublist: 2,
                                           summarize_validation: 3]
  alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi2, as: AnimalApi

  alias Crit.Ecto.TrimmedString
  alias CritBiz.ViewModels.FieldFillers.{FromWeb, ToWeb}
  alias CritBiz.ViewModels.FieldValidators
  alias Ecto.Changeset
  alias Ecto.ChangesetX
  import Pile.Deftestable
  use ExContract

  @primary_key false   # I do this to emphasize `id` is just another field
  embedded_schema do
    field :id, :id
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :lock_version, :integer
    
    # Fields used for displays or forms presented to a human
    field :institution, :string
    field :in_service_datestring, :string
    field :out_of_service_datestring, :string
    field :species_name, :string

    field :service_gaps, {:array, :map}
  end

  def fields(), do: __schema__(:fields)
  def required(),
    do: [:name, :lock_version, :in_service_datestring, :out_of_service_datestring]


  # ----------------------ABOUT PRODUCING A FORM: `fetch`, `lift` ----------------
  
  @spec fetch(:atom, short_name()) :: VM.Animal | [VM.Animal]
  
  def fetch(:all_possible, institution) do
      AnimalApi.inadequate_all(institution, preload: [:species])
      |> lift(institution)
  end

  def fetch(:one_for_summary, id, institution) do
    AnimalApi.one_by_id(id, institution, preload: [:species])
    |> lift(institution)
  end

  def fetch(:one_for_edit, id, institution) do
    AnimalApi.one_by_id(id, institution, preload: [:species, :service_gaps])
    |> lift(institution)
  end
  
  @spec fresh_form_changeset(VM.Animal) :: Changeset.t(VM.Animal)
  def fresh_form_changeset(animal) do
    animal
    |> Map.update!(:service_gaps, &([%VM.ServiceGap{} | &1]))
    |> Changeset.change
  end

  
  deftestable lift(sources, institution) when is_list(sources), 
    do: (for s <- sources, do: lift(s, institution))
    
  @spec lift(AnimalApi.t, short_name()) :: VM.Animal
  deftestable lift(source, institution) do
    %{EnumX.pour_into(source, VM.Animal) |
      species_name: source.species.name,
      institution: institution
    }
    |> ToWeb.service_datestrings(source.span)
    |> ToWeb.when_loaded(:service_gaps, source,
                         &(VM.ServiceGap.lift(&1, institution)))
  end

  # -----------------TURNING AN HTTP FORM INTO AN `AnimalVM` changeset -----------

  # This could use cast_assoc, but it's just as easy to process the
  # changesets separately, especially because the `institution` argument
  # has to be dragged around.
  @spec accept_form(params(), short_name()) :: Changeset.t(VM.Animal)
  def accept_form(params, institution) do
    params = flatten_numbered_sublist(params, "service_gaps")

    animal_changeset = 
      %VM.Animal{institution: institution}
      |> cast(params, fields())
      |> validate_required(required())
      |> FieldValidators.date_order

    sg_changesets = 
      for sg_params <- fetch_change!(animal_changeset, :service_gaps) do
        VM.ServiceGap.accept_form(sg_params, institution)
      end

    animal_changeset
    |> put_change(:service_gaps, sg_changesets)
    |> summarize_validation(
          ChangesetX.all_valid?(animal_changeset, sg_changesets),
          error_subtype: :form)
  end

  # ---------Changeset for Schemas Version ---------------------------------------

  @spec lower_changeset(Changeset.t(VM.Animal), db_id, short_name())
  :: Changeset.t(Schemas.Animal)
        
  def lower_changeset(form_changeset, id, institution) do
    lower_attrs = lower_to_attrs(form_changeset)
    ids_to_delete = ChangesetX.ids_to_delete_from(form_changeset, :service_gaps)
    
    id
    |> AnimalApi.one_by_id(institution, preload: [:service_gaps])
    |> Schemas.Animal.changeset(lower_attrs)
    |> VM.ServiceGap.mark_deletions(ids_to_delete)
  end

  @spec lower_to_attrs(Changeset.t(VM.Animal)) :: attrs()
  deftestable lower_to_attrs(changeset) do
    data = apply_changes(changeset)
    %{name: data.name,
      lock_version: data.lock_version,
      span: FromWeb.span(data),
      service_gaps: VM.ServiceGap.lower_to_attrs(data.service_gaps)
    }
  end

  # ----------------------------------------------------------------------------

  # Note: This goes to the trouble of reloading the updated animal.
  # This is safest in the face of future changes, and it avoids awkwarness
  # like having to drag around the species data even though that can
  # never be updated.

  @spec update(Changeset.t(Schemas.Animal), short_name()) :: nary_error()
  def update(changeset, institution) do
    check changeset.valid?

    stale_error_handling = [
      stale_error_field: :optimistic_lock_error,
      # There is no need to set the message, as it will be overridden below.
    ]
    
    case Sql.update(changeset, stale_error_handling, institution) do
      {:ok, %{id: id}} ->
        {:ok, fetch(:one_for_summary, id, institution)}
      {:error, changeset} ->
        if Keyword.has_key?(changeset.errors, :optimistic_lock_error) do
          {:error, :optimistic_lock, Changeset.get_field(changeset, :id)}
        else
          {:error, :constraint, changeset}
        end
    end
  end
end
