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
    alias Ecto.Multi
    alias Crit.Sql
    
    defp animal_key(index), do: {:animal, index}
    defp is_animal_key?({:animal, _count}), do: true
    defp is_animal_key?(_), do: false

    defp animal_ids(_repo, map_with_animals) do
      reducer = fn {key, value}, acc ->
        case is_animal_key?(key) do
          true ->
            [value.id | acc]
          false ->
            acc
        end
      end

      result = 
        map_with_animals
        |> Enum.reduce([], reducer)
        |> Enum.reverse
      {:ok, result}
    end

    def creation(changesets, institution) do
      add_insertion = fn {changeset, index}, acc ->
        Multi.insert(acc, animal_key(index), changeset, Sql.multi_opts(institution))
      end

      changesets
      |> Enum.with_index
      |> Enum.reduce(Multi.new, add_insertion)
      |> Multi.run(:animal_ids, &animal_ids/2)
    end


    def params_to_ids(params, institution) do
      {:ok, changesets} = Animal.creational_changesets(params)
      
      changesets
      |> creation(institution)
      |> Sql.transaction(institution)
      |> result_animal_ids
    end
    
    def result_animal_ids({:ok, %{animal_ids: animal_ids}}), do: animal_ids
  end
end
