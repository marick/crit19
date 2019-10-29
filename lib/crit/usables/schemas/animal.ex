defmodule Crit.Usables.Schemas.Animal do

  @doc """
  I'd rather call this module `Animal.Schema` but then having foreign
  keys like `:animal_id` becomes awkward.
  """
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias Crit.Usables.HiddenSchemas.Species
  import Ecto.Changeset
  alias Crit.Usables.FieldConverters.ToDate

  schema "animals" do
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :in_service_date, :date
    field :out_of_service_date, :date
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    
    # field :species_id is as well, but it's created by `belongs_to` below.
    timestamps()

    belongs_to :species, Species

    field :timezone, :string, virtual: true
    field :species_name, :string, virtual: true
    field :in_service_datestring, :string, virtual: true
    field :out_of_service_datestring, :string, virtual: true
  end

  # This changeset comes from bulk creation with the datestrings
  # already turned into dates. This is perilous - rethink?
  def from_bulk_creation_changeset(attrs) do
    required = [:name, :species_id, :lock_version, :in_service_date]
    relevant = required ++ [:out_of_service_date]
    %__MODULE__{}
    |> cast(attrs, relevant)
    |> validate_required(required)
    |> constraint_on_name()
  end

  def form_changeset(animal) do 
    change(animal)
  end

  def update_changeset(struct, attrs) do
    required = [:name, :lock_version,
                :in_service_datestring, :out_of_service_datestring]
    struct
    |> cast(attrs, required)
    |> validate_required(required)
    |> ToDate.put_service_dates
    |> constraint_on_name()
    |> optimistic_lock(:lock_version)
  end
  
  defp constraint_on_name(changeset),
    do: unique_constraint(changeset, :name, name: "unique_available_names")
end
