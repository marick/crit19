defmodule CritBiz.ViewModels.Setup.BulkAnimalNew do
  use CritBiz, :view_model
  # alias Ecto.Datespan
  alias CritBiz.ViewModels.Setup, as: VM
  import CritBiz.ViewModels.Common, only: [summarize_validation: 3]
  alias CritBiz.ViewModels.FieldFillers.FromWeb
  alias CritBiz.ViewModels.FieldValidators
  alias Crit.Setup.Schemas
  alias Ecto.Changeset
  alias Pile.Namelist
  alias Crit.Ecto.BulkInsert
  alias Crit.Sql
  alias Crit.Setup.AnimalApi2, as: AnimalApi

  @primary_key false
  embedded_schema do
    # user-supplied fields
    field :names, :string,                      default: ""
    field :species_id, :integer
    field :in_service_datestring, :string,      default: @today
    field :out_of_service_datestring, :string,  default: @never
    # The institution is needed to determine the timezone to see
    # what day "today" is.
    field :institution, :string
  end

  def fields(), do: __schema__(:fields)
  def required(),
    do: ListX.delete(fields(), [:institution, :names]) # names checked differently

  def fresh_form_changeset(), do: changeset(%__MODULE__{}, %{})

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, fields())
    |> validate_required(required())
  end

  # ----------------------------------------------------------------------------

  @spec accept_form(params(), short_name()) :: Changeset.t(VM.BulkAnimalNew)
  def accept_form(params, institution) do
    changeset = 
      %__MODULE__{institution: institution}
      |> changeset(params)
      |> FieldValidators.date_order
      |> FieldValidators.namelist(:names)
    summarize_validation(changeset, changeset.valid?, error_subtype: :form)
  end

  # ----------------------------------------------------------------------------

  @spec lower_changeset(Changeset.t(VM.BulkAnimalNew))
  :: [Schemas.Animal]
  def lower_changeset(vm_changeset) do
    for name <- Namelist.to_list(Changeset.fetch_change!(vm_changeset, :names)) do
      %Schemas.Animal{
        id: nil,  # for insertion
        name: name,
        span: FromWeb.span(vm_changeset),
        species_id: Changeset.fetch_field!(vm_changeset, :species_id)
      }
    end
  end

  # ----------------------------------------------------------------------------

  @spec insert_all([Schemas.Animal], short_name()) :: nary_error(VM.Animal)
  def insert_all(animals, institution) do
    case script(animals, institution) |> run_script(institution) do
      {:ok, animal_ids} -> 
        vm_animals =
          animal_ids
          |> AnimalApi.all_by_ids(institution, preload: [:species])
          |> VM.Animal.lift(institution)
        {:ok, vm_animals}
    end
    
    # |> Sql.Transaction.on_error(original_changeset, name: transfer_name_error())
    
  end

  defp script(animals, institution) do 
    animals
    |> BulkInsert.idlist_script(institution, schema: Schemas.Animal, ids: :animal_ids)
  end

  defp run_script(script, institution) do
    script
    |> Sql.transaction(institution)
    |> Sql.Transaction.on_ok(extract: :animal_ids)
  end
end
