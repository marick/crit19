defmodule CritWeb.ViewModels.Setup.Animal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.TrimmedString
  alias CritWeb.ViewModels.Setup, as: VM
#  alias Crit.Setup.Schemas
  alias Crit.Setup.AnimalApi2, as: AnimalApi
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

  # ----------------------------------------------------------------------------
  def accept_form(params, institution) do
    params =
      params
      |> Map.put("service_gaps", Map.values(params["service_gaps"]))
    
    %VM.Animal{institution: institution}
    |> cast(params, fields())
    |> validate_required(required())
    |> FieldValidators.date_order
    |> FieldValidators.cast_sublist(:service_gaps, fn sublist -> 
          VM.ServiceGap.accept_forms(sublist, institution)
       end)
  end

  # ----------------------------------------------------------------------------

  def prepare_for_storage(_id, _changeset) do
  end

  # ----------------------------------------------------------------------------

  def update(_changeset, _institution) do
  end
  
  # ----------------------------------------------------------------------------

  def lift(sources, institution) when is_list(sources), 
    do: (for s <- sources, do: lift(s, institution))

  def lift(source, institution) do
    %{EnumX.pour_into(source, VM.Animal) |
      species_name: source.species.name,
      institution: institution
    }
    |> ToWeb.service_datestrings(source.span)
    |> ToWeb.when_loaded(:service_gaps, source,
                         &(VM.ServiceGap.lift(&1, institution)))
  end

  # ----------------------------------------------------------------------------


  def update_params(changeset) do
    {:ok, data} = apply_action(changeset, :insert)
    %{name: data.name,
      lock_version: data.lock_version,
      span: FromWeb.span(data),
      service_gaps: VM.ServiceGap.update_params(data.service_gaps)
    }
  end
end
