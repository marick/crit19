defmodule Crit.Schemas.Animal do
  use Ecto.Schema
  alias Crit.Ecto.TrimmedString
  alias Crit.Schemas
  alias Ecto.Datespan
  import Ecto.Changeset

  schema "animals" do
    field :name, TrimmedString
    field :span, Datespan
    field :available, :boolean, default: true
    field :lock_version, :integer, default: 1
    belongs_to :species, Schemas.Species
    has_many :service_gaps, Schemas.ServiceGap
    timestamps()
  end

  def preloads, do: [:species, :service_gaps]
  def fields(), do: __schema__(:fields)
  def required(), do: ListX.delete(fields(), [:id, :species_id])

  def changeset(%__MODULE__{} = current, attrs) do
    current
    |> cast(attrs, fields())
    |> cast_assoc(:service_gaps)
    |> validate_required(required())
    |> constrained
  end

  def constrained(%__MODULE__{} = animal),
    do: change(animal) |> constrained

  def constrained(changeset),
    do: changeset |> constraint_on_name |> optimistic_lock(:lock_version)

  defp constraint_on_name(changeset),
    do: unique_constraint(changeset, :name, name: "unique_available_names")


  defmodule Get do
    alias Crit.Sql
    use Crit.Sql.CommonSql, schema: Crit.Schemas.Animal

    deftypical(:all_by_species, :all, species_id: species_id)
    deftypical(:one_by_id, :one, id: id)
    def_all_by_Xs(:id)


    # It would be better if we only dealt with animals that are
    # active and in service as of a particular date
    def inadequate_all(institution, opts \\ []) do 
      Sql.CommonQuery.typical(target_schema(), opts)
      |> Sql.all(institution)
    end
  end

  defmodule Query do
    import Ecto.Query
    import Ecto.Datespan

    def by_in_service_date(date, species_id) do
      from a in Crit.Schemas.Animal,
        where: a.species_id == ^species_id,
        where: a.available == true,
        where: contains_point_fragment(a.span, ^date)
    end
  end
end
