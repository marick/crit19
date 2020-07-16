defmodule CritBiz.ViewModels.Setup.BulkAnimal do
  use CritBiz, :view_model
  alias CritBiz.ViewModels.Setup, as: VM
  alias Crit.Schemas
  
  alias CritBiz.ViewModels.FieldFillers.FromWeb
  alias CritBiz.ViewModels.FieldValidators
  alias Pile.Namelist
  alias Crit.Ecto.BulkInsert

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

  @spec accept_form(params(), short_name()) :: Changeset.t(VM.BulkAnimal)
  def accept_form(params, institution) do
    changeset = 
      %__MODULE__{institution: institution}
      |> changeset(params)
      |> FieldValidators.date_order
      |> FieldValidators.namelist(:names)
    summarize_validation(changeset, changeset.valid?, error_subtype: :form)
  end

  # ----------------------------------------------------------------------------

  @spec lower_changeset(Changeset.t(VM.BulkAnimal)) :: [Schemas.Animal]
  def lower_changeset(vm_changeset) do
    for name <- Namelist.to_list(fetch_change!(vm_changeset, :names)) do
      %Schemas.Animal{
        id: nil,  # for insertion
        name: name,
        span: FromWeb.span(vm_changeset),
        species_id: fetch_field!(vm_changeset, :species_id)
      }
    end
  end

  # ----------------------------------------------------------------------------

  @spec insert_all([Schemas.Animal], short_name()) :: nary_error(VM.Animal)
  def insert_all(animals, institution) do
    insertion_result =
      animals
      |> Enum.map(&Schemas.Animal.constrained/1)
      |> BulkInsert.idlist_script(institution,
                                  schema: Schemas.Animal,
                                  ids: :animal_ids)
      |> Sql.transaction(institution)
      |> Sql.Transaction.simplify_result(extract: :animal_ids)
    
    case insertion_result do
      {:ok, animal_ids} -> 
        {:ok, VM.Animal.fetch(:all_for_summary_list, animal_ids, institution)}
      {:error, _index, changeset} ->
        name = ChangesetX.new!(changeset, :name)
        message = ~s[An animal named "#{name}" is already in service]

        {:error, :constraint, %{message: message}}
    end
  end
end
