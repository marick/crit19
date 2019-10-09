defmodule Crit.Usables.Write.Animal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.TrimmedString
  alias Crit.Sql

  schema "animals" do
    field :name, TrimmedString
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    field :species_id, :integer
    timestamps()
  end

  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name, :species_id, :lock_version])
    |> validate_required([:name, :species_id, :lock_version])
    |> unique_constraint(:name, name: "unique_available_names")
  end

  def changeset(fields) when is_list(fields) do
    changeset(%__MODULE__{}, Enum.into(fields, %{}))
  end

  def update_for_id(string_id, attrs, institution) do
    id = String.to_integer(string_id)
    {:ok, _} = 
      %__MODULE__{id: id}
      |> cast(attrs, [:name])
      |> Sql.update(institution)
    {:ok, id}
  end


end
