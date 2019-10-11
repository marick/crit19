defmodule Crit.Usables.Write.Animal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.TrimmedString
  alias Crit.Usables.Write
  alias Crit.Sql

  schema "animals" do
    # The fields below are the true fields in the table.
    field :name, TrimmedString
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    # field :species_id is as well, but it's created by `belongs_to` below.
    timestamps()

    belongs_to :species, Write.Species
    many_to_many :service_gaps, Write.ServiceGap, join_through: "animal__service_gap"

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

  def edit_changeset(animal) do 
    change(animal)
  end
  

  def update_for_id(string_id, attrs, institution) do
    id = String.to_integer(string_id)

    db_result = 
      %__MODULE__{id: id}
      |> cast(attrs, [:name])
      |> constraint_on_name()
      |> optimistic_lock(:lock_version)
      |> Sql.update([stale_error_field: :optimistic_lock_error], institution)

    case db_result do 
      {:ok, _} -> 
        {:ok, id}
      _ -> 
        db_result
    end
  end

  defp constraint_on_name(changeset),
    do: unique_constraint(changeset, :name, name: "unique_available_names")
end
