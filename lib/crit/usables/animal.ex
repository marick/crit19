defmodule Crit.Usables.Animal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Usables.{ServiceGap, Species, AnimalServiceGap}
  alias Crit.Ecto.{NameList, TrimmedString}


  schema "animals" do
    field :name, TrimmedString
    belongs_to :species, Species
    field :lock_version, :integer, default: 1
    many_to_many :service_gaps, ServiceGap,
      join_through: AnimalServiceGap

    field :names, NameList, virtual: true
    timestamps()
  end

  @doc false
  def changeset(animal, attrs) do
    animal
    |> cast(attrs, [:name, :species_id, :lock_version])
    |> validate_required([:name, :species_id, :lock_version])
  end

  def creational_changesets(attrs) do
    checked_input = 
      %__MODULE__{}
      |> cast(attrs, [:names, :species_id, :lock_version])
      |> validate_required([:names, :species_id, :lock_version])

    spread_names = fn changeset -> 
      Enum.map(changeset.changes.names, fn name ->
        put_change(changeset, :name, name)
      end)
    end

    case checked_input.valid? do
      false -> {:error, checked_input}
      true -> {:ok, spread_names.(checked_input)}
    end
  end

  defmodule Query do
    import Ecto.Query
    alias Crit.Usables.Animal

    def complete(id) do
      from a in Animal,
        where: a.id == ^id,
        preload: [:service_gaps, :species]
    end
  end


  defmodule TxPart do
    alias Crit.Usables.Animal
    use Ecto.MegaInsertion,
      individual_result_prefix: :animal,
      idlist_result_prefix: :animal_ids


    def params_to_ids(params, institution) do
      {:ok, changesets} = Animal.creational_changesets(params)
      run_for_ids(changesets, institution)
    end
    
  end
end
