defmodule CritWeb.ViewModels.Procedure.Creation do
  use Ecto.Schema
  # use Crit.Global.Constants
  # alias Crit.Setup.InstitutionApi
  import Ecto.Changeset
  alias Crit.Setup.Schemas.Procedure

  embedded_schema do
    field :index, :integer
    field :name, :string, default: ""
    field :species_ids, {:array, :id}
  end

  @required [:name, :species_ids]

  def starting_changeset() do
    %__MODULE__{}
    |> cast(%{}, @required)
    |> validate_required(@required)
  end

  def changeset(struct, attrs) do
    struct
    |> cast(attrs, @required)
    |> validate_required(@required)
  end
    

  def changesets(descriptions) do
    changesets = Enum.map(descriptions, &(changeset(%__MODULE__{}, &1)))
    case Enum.all?(changesets, &(&1.valid?)) do
      true -> {:ok, changesets}
    end
  end

  def unfold_to_attrs([only]) do
    [%{name: fetch_field!(only, :name),
       species_id: List.first(fetch_field!(only, :species_ids))}]
  end

end
