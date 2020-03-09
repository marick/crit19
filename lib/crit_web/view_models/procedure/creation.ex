defmodule CritWeb.ViewModels.Procedure.Creation do
  use Ecto.Schema
  import Ecto.Changeset
  # alias Crit.Setup.Schemas.Procedure

  embedded_schema do
    field :index, :integer
    field :name, :string, default: ""
    field :species_ids, {:array, :id}, default: []
  end

  @required [:name, :species_ids, :index]

  def legit_error_messages do
    %{at_least_one_species: "You must choose at least one species"}
  end

  def starting_changeset() do
    %__MODULE__{}
    |> cast(%{}, @required)
    |> validate_required(@required)
  end

  def changeset(struct, attrs) do
    start = cast(struct, attrs, @required)
    case {fetch_change(start, :name), fetch_change(start, :species_ids)} do
      {:error, :error} -> start
      {:error, _} -> start
      {_, :error} -> add_error(start, :species_ids, legit_error_messages().at_least_one_species)
      {_, _} -> start
    end
  end
    

  def changesets(descriptions) do
    changesets = Enum.map(descriptions, &(changeset(%__MODULE__{}, &1)))
    case Enum.all?(changesets, &(&1.valid?)) do
      true -> {:ok, changesets}
      false -> {:error, changesets}
    end
  end

  def unfold_to_attrs(changesets) do
    one_set = fn name, species_id -> 
      %{name: name, species_id: species_id}
    end

    Enum.flat_map(changesets, fn changeset ->
      case fetch_change(changeset, :name) do
        {:ok, name} -> 
          Enum.map(fetch_change!(changeset, :species_ids), &(one_set.(name, &1)))
        _ ->
          []
      end
    end)
  end

end
