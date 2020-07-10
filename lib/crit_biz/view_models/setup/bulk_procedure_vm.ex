defmodule CritBiz.ViewModels.Setup.BulkProcedure do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Schemas
  alias Ecto.Multi
  alias Crit.Sql
  use Crit.Errors

  # The index is used to give each element of the array its own unique id.
  # That may not be necessary, but it doesn't hurt and is arguably clearer.
  embedded_schema do
    field :index, :integer
    field :name, :string, default: ""
    field :species_ids, {:array, :id}, default: []
    field :frequency_id, :integer
  end

  @required [:name, :species_ids, :index, :frequency_id]

  def starting_changeset() do
    %__MODULE__{}
    |> cast(%{}, @required)
  end

  def changeset(%__MODULE__{} = struct, attrs) do
    start = cast(struct, attrs, @required)
    case {fetch_change(start, :name), fetch_change(start, :species_ids)} do
      {:error, :error} -> start
      {:error, _} -> start
      {_, :error} -> add_error(start, :species_ids, @at_least_one_species)
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

  def insert_changesets(changesets, institution) do
    case make_multi(changesets, institution)|> Sql.transaction(institution) do
      {:ok, from_multi_id__to__procedure} ->
        {:ok, Map.values(from_multi_id__to__procedure)}
      {:error, insertion_id, failing_changeset, _previous_results} ->
        {:error, transfer_multi_error(insertion_id, failing_changeset, changesets)}
    end
  end

  # -------------------------------------------------------------------0- 

  def unfold_to_attrs(changesets) do # public for testing
    one_set = fn %{changes: changes}, species_id ->
      %{name: changes.name,
        species_id: species_id,
        frequency_id: changes.frequency_id}
    end

    Enum.flat_map(changesets, fn changeset ->
      case fetch_change(changeset, :name) do
        {:ok, _} -> 
          Enum.map(fetch_change!(changeset, :species_ids), &(one_set.(changeset, &1)))
        _ ->
          []
      end
    end)
  end

  defp make_multi(changesets, institution) do
    reducer = fn attrs, multi ->
      Multi.insert(multi,
        {attrs.name, attrs.species_id},
        Schemas.Procedure.changeset(%Schemas.Procedure{}, attrs),
        Sql.multi_opts(institution))
    end

    changesets
    |> unfold_to_attrs 
    |> Enum.reduce(Multi.new, reducer)
  end

  defp transfer_multi_error( {name, _id}, %{errors: [name: {msg, _}]}, changesets) do
    index = Enum.find_index(changesets, fn changeset ->
      changeset.changes.name == name
    end)
    
    changesets
    |> List.update_at(index, &(add_error(&1, :name, msg)))
  end
end
