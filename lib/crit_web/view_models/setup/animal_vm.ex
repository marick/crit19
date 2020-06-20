defmodule CritWeb.ViewModels.Setup.Animal do
  use CritWeb, :view_model
  alias CritWeb.ViewModels.Setup, as: VM
  alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi2, as: AnimalApi

  alias Crit.Ecto.TrimmedString
  alias CritWeb.ViewModels.FieldFillers.{FromWeb, ToWeb}
  alias CritWeb.ViewModels.FieldValidators

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
    
  @spec lift(AnimalApi.t, String.t) :: Changeset.t(AnimalVM.t)
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
  @spec accept_form(params(), String.t) :: Changeset.t
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

  def update_params(changeset) do
    data = apply_changes(changeset)
    %{name: data.name,
      lock_version: data.lock_version,
      span: FromWeb.span(data),
      service_gaps: VM.ServiceGap.update_params(data.service_gaps)
    }
  end

  def deletion_ids(service_gap_changesets) do
    service_gap_changesets
    |> Enum.filter(&(get_change(&1, :delete, false)))
    |> Enum.map(&get_change(&1, :id))
    |> MapSet.new
  end

  def prepare_for_update(id, vm_changeset, institution) do
    params = update_params(vm_changeset)
    old_version = AnimalApi.one_by_id(id, institution, preload: [:service_gaps])
    
    deletion_ignorant = Schemas.Animal.changeset(old_version, params)

    to_delete =
      vm_changeset
      |> fetch_field!(:service_gaps)
      |> deletion_ids

    mark_deletion = fn ecto_changeset ->
      if MapSet.member?(to_delete, fetch_field!(ecto_changeset, :id)) do
        %{ecto_changeset | action: :delete}
      else
        ecto_changeset
      end
    end

    guaranteed_changesets =
      get_change(deletion_ignorant, :service_gaps,
        fetch_field!(deletion_ignorant, :service_gaps)
        |> Enum.map(&(change &1, %{})))

    service_gaps_with_deletion =
      Enum.map(guaranteed_changesets, mark_deletion)

    put_change(deletion_ignorant, :service_gaps, service_gaps_with_deletion)
  end


  # ----------------------------------------------------------------------------

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
