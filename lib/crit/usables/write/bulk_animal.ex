defmodule Crit.Usables.Write.BulkAnimal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.{NameList, TrimmedString}


  embedded_schema do
    field :names, :string
    field :species_id, :integer
    field :start_date, :string
    field :end_date, :string
    field :timezone, :string

    field :computed_start_date, :date, virtual: true
    field :computed_end_date, :date, virtual: true
    field :computed_names, {:array, :string}, virtual: true
    field :computed_service_gaps, {:array, ServiceGap}, virtual: true
  end

  @required [:names, :species_id, :start_date, :end_date, :timezone]

  def changeset(bulk, attrs) do
    bulk
    |> cast(attrs, @required)
    |> validate_required(@required)
  end


  def compute_insertables(attrs) do
    required = changeset(%__MODULE__{}, attrs)

    if required.valid? do 
      required 
      |> compute_names
      |> compute_dates
      |> compute_service_gaps
    else
      required
    end
  end

  def compute_names(changeset) do
    names = changeset.changes.names
    case NameList.cast(names) do
      {:ok, []} ->
        add_error(changeset, :names, "must have at least one valid name")
      {:ok, namelist} -> 
        put_change(changeset, :computed_names, namelist)
      _ -> 
        add_error(changeset, :names, "has something unexpected wrong with it. Sorry.")
    end
  end

  def compute_dates(changeset) do
    changeset
  end



  def compute_service_gaps(changeset) do
    changeset
  end


end
