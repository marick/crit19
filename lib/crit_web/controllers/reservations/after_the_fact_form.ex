defmodule CritWeb.Reservations.AfterTheFactForm do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Setup.InstitutionApi
  # import Pile.ChangesetFlow
  # alias Crit.FieldConverters.{ToSpan, ToNameList}
  alias Ecto.Timespan


  embedded_schema do
    field :species_id, :integer
    field :date, :date
    field :date_showable_date, :string
    field :part_of_day_id, :string
    field :institution, :string
    
    field :species_name, :string
    field :timespan, Timespan
  end

  @form_1_fields [:species_id, :date, :date_showable_date,
                  :part_of_day_id, :institution]

  def empty do
    change(%__MODULE__{})
  end

  def form_1_changeset(attrs) do
    empty()
    |> cast(attrs, @form_1_fields)
    |> validate_required(@form_1_fields)
    |> synthesize_species
  end


  def synthesize_species(changeset) do
    id = get_change(changeset, :species_id)
    institution = get_change(changeset, :institution)
    name = InstitutionApi.species_name(id, institution)
    put_change(changeset, :species_name, name)
  end
end
