defmodule Crit.Usables.Schemas.Animal do

  @doc """
  I'd rather call this module `Animal.Schema` but then having foreign
  keys like `:animal_id` becomes awkward.
  """
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias Crit.Usables.HiddenSchemas.Species
  alias Crit.Usables.Schemas.ServiceGap
  import Ecto.Changeset

  schema "animals" do
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    # field :species_id is as well, but it's created by `belongs_to` below.
    timestamps()

    belongs_to :species, Species
    many_to_many :service_gaps, ServiceGap, join_through: "animal__service_gap"

    field :species_name, :string, virtual: true
    field :in_service_date, :string, virtual: true
    field :out_of_service_date, :string, virtual: true
  end


  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name, :species_id, :lock_version])
    |> validate_required([:name, :species_id, :lock_version])
    |> constraint_on_name()
  end

  def changeset(fields) when is_list(fields) do
    changeset(%__MODULE__{}, Enum.into(fields, %{}))
  end

  def form_changeset(animal) do 
    change(animal)
  end

  def update_changeset(id, attrs) do
    %__MODULE__{id: id}
    |> cast(attrs, [:name, :lock_version])
    |> constraint_on_name()
    |> optimistic_lock(:lock_version)
  end
  
  defp constraint_on_name(changeset),
    do: unique_constraint(changeset, :name, name: "unique_available_names")
end
