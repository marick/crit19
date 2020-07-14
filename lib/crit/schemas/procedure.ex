defmodule Crit.Schemas.Procedure do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.TrimmedString
  alias Crit.Schemas.{Species,ProcedureFrequency}
  alias Crit.Sql

  schema "procedures" do
    field :name, TrimmedString
    belongs_to :species, Species
    belongs_to :frequency, ProcedureFrequency

    timestamps()
  end

  def associations, do: __schema__(:associations)

  @required [:name, :species_id, :frequency_id]

  def changeset(%__MODULE__{} = procedure, attrs) do
    procedure
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> constrained
  end

  def constrained(%__MODULE__{} = procedure),
    do: change(procedure) |> constrained

  def constrained(changeset),
    do: changeset |> constraint_on_name

  defp constraint_on_name(changeset),
    do: unique_constraint(changeset, :name, name: "unique_to_species")

  defmodule Get do
    use Crit.Sql.CommonSql, schema: Crit.Schemas.Procedure

    deftypical(:all_by_species, :all, species_id: species_id)
    deftypical(:one_by_id, :one, id: id)
    def_all_by_Xs(:id)
  end

  def insert(attrs, institution) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Sql.insert(institution)
  end
end
