defmodule CritWeb.Reservations.AfterTheFact.StartData do
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
    field :time_slot_id, :integer
    field :institution, :string
    
    field :species_name, :string
    field :time_slot_name, :string
    field :span, Timespan
    field :transaction_key, :string
    field :animal_names, :map
  end

  @required [:species_id, :date, :date_showable_date,
             :time_slot_id, :institution]

  def empty do
    change(%__MODULE__{})
  end

  def changeset(attrs) do
    empty()
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> add_species_name
    |> add_animal_names
    |> add_span
    |> add_time_slot_name
  end

  def add_species_name(changeset) do
    put_change(changeset, :species_name, species_name_from(changeset))
  end

  def add_animal_names(changeset) do
    changeset
  end

  def add_span(changeset) do
    args =
      [:date, :time_slot_id, :institution]
      |> Enum.map(&(get_change changeset, &1))
    
    result = apply(InstitutionApi, :timespan, args)
    put_change(changeset, :span, result)
  end

  def add_time_slot_name(changeset) do
    put_change(changeset, :time_slot_name, time_slot_name_from(changeset))
  end


  defp institution(changeset),
    do: get_change(changeset, :institution)

  defp species_id(changeset),
    do: get_change(changeset, :species_id)

  defp time_slot_id(changeset),
    do: get_change(changeset, :time_slot_id)

  defp species_name_from(changeset) do
    InstitutionApi.species_name(species_id(changeset), institution(changeset))
  end

  def time_slot_name_from(changeset) do
    InstitutionApi.time_slot_name(time_slot_id(changeset), institution(changeset))
  end
end
