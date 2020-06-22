defmodule CritWeb.ViewModels.Setup.Animal do
  use CritWeb, :view_model
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi2, as: AnimalApi

  alias Crit.Ecto.TrimmedString
  alias CritWeb.ViewModels.FieldFillers.{FromWeb, ToWeb}
  alias CritWeb.ViewModels.FieldValidators
  alias Ecto.ChangesetX

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
  
  @spec fetch(:atom, short_name()) :: Changeset.t(VM.Animal)
  
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

  
  def lift(sources, institution) when is_list(sources), 
    do: (for s <- sources, do: lift(s, institution))
    
  @spec lift(AnimalApi.t, short_name()) :: Changeset.t(VM.Animal)
  def lift(source, institution) do
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
    params = CritWeb.ViewModels.Common.flatten(params, "service_gaps")

    animal_changeset = 
      %VM.Animal{institution: institution}
      |> cast(params, fields())
      |> validate_required(required())
      |> FieldValidators.date_order
    
    sg_changesets =
      fetch_change!(animal_changeset, :service_gaps)
      |> Enum.reject(&VM.ServiceGap.from_empty_form?/1)
      |> Enum.map(&(VM.ServiceGap.accept_form &1, institution))

    result = 
      animal_changeset
      |> put_change(:service_gaps, sg_changesets)
      |> Map.put(:valid?, ChangesetX.all_valid?(animal_changeset, sg_changesets))

    case result.valid? do
      true -> {:ok, result}
      false -> {:error, :form, result}
    end
  end

  # ----------------------------------------------------------------------------

  @spec lower_changeset(db_id, Changeset.t(VM.Animal), short_name())
  :: Changeset.t(Schemas.Animal)
        
  def lower_changeset(id, form_changeset, institution) do
    lower_attrs = lower_to_attrs(form_changeset)
    ids_to_delete = ChangesetX.ids_to_delete_from(form_changeset, :service_gaps)
    
    id
    |> AnimalApi.one_by_id(institution, preload: [:service_gaps])
    |> Schemas.Animal.changeset(lower_attrs)
    |> VM.ServiceGap.mark_deletions(ids_to_delete)
  end

  @spec lower_to_attrs(Changeset.t(VM.Animal)) :: attrs()
  def lower_to_attrs(changeset) do
    data = apply_changes(changeset)
    %{name: data.name,
      lock_version: data.lock_version,
      span: FromWeb.span(data),
      service_gaps: VM.ServiceGap.lower_to_attrs(data.service_gaps)
    }
  end

  def deletion_ignorant_ecto_changeset(id, form_changeset, institution) do 
    old_version = AnimalApi.one_by_id(id, institution, preload: [:service_gaps])
    attrs = lower_to_attrs(form_changeset)
    
    Schemas.Animal.changeset(old_version, attrs)
  end

  # ----------------------------------------------------------------------------

  @spec update(Changeset.t(Schemas.Animal), short_name()) :: nary_error()
  def update(changeset, institution) do
    result =
      Sql.update(changeset, [stale_error_field: :optimistic_lock_error], institution)
    case result do
      {:ok, %{id: id}} ->
        {:ok, fetch(:one_for_summary, id, institution)}
    end
  end
  
  # ----------------------------------------------------------------------------

end
