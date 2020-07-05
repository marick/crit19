defmodule CritBiz.ViewModels.Setup.BulkAnimalNew do
  use CritBiz, :view_model
#  import Pile.ChangesetFlow
  # alias Crit.FieldConverters.{ToSpan, ToNameList}
#  alias Ecto.Datespan

  embedded_schema do
    # user-supplied fields
    field :names, :string,                      default: ""
    field :species_id, :integer
    field :in_service_datestring, :string,      default: @today
    field :out_of_service_datestring, :string,  default: @never
    # The institution is needed to determine the timezone to see
    # what day "today" is.
    field :institution, :string

    # computed fields
    field :computed_names, {:array, :string},   default: []
  end

  def fields(), do: __schema__(:fields)
  def required(),
    do: ListX.delete(fields(), [:institution, :computed_names])

  def fresh_form_changeset(), do: changeset(%__MODULE__{}, %{})

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, required())
    |> validate_required(required())
  end

  # ----------------------------------------------------------------------------

  @spec accept_form(params(), short_name()) :: Changeset.t(VM.BulkAnimalNew)
  def accept_form(_params, _institution) do
  end

  # ----------------------------------------------------------------------------

  @spec lower_changeset(Changeset.t(VM.BulkAnimalNew), short_name())
  :: [Changeset.t(Schemas.Animal)]

  def lower_changeset(_vm_changeset, _institution) do
    
  end

  # ----------------------------------------------------------------------------

  @spec create([Changeset.t(Schemas.Animal)], short_name()) :: nary_error()
  def create(_changeset, _institution) do
  end
end
