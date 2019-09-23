defmodule Crit.Usables.Write.BulkAnimal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.{NameList}
  alias Ecto.Datespan
  alias Crit.Usables.ServiceGap
  alias Crit.Usables.Write.{DateComputers}


  embedded_schema do
    field :names, :string
    field :species_id, :integer
    field :start_date, :string
    field :end_date, :string
    field :timezone, :string

    field :computed_start_date, :date, virtual: true
    field :computed_end_date, :date, virtual: true
    field :computed_names, {:array, :string}, virtual: true
    field :computed_service_gaps, {:array, Datespan}, virtual: true
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
      |> DateComputers.start_and_end
      |> compute_service_gaps
    else
      required
    end
  end

  def compute_names(changeset) do
    names = changeset.changes.names
    case NameList.cast(names) do
      {:ok, []} ->
        add_error(changeset, :names, no_names_error_message())
      {:ok, namelist} -> 
        put_change(changeset, :computed_names, namelist)
      _ -> 
        add_error(changeset, :names, impossible_error_message())
    end
  end
  
  def compute_service_gaps(%{valid?: false} = changeset), do: changeset
  def compute_service_gaps(%{changes: changes} = changeset) do
    computed_start_date = changes[:computed_start_date]
    computed_end_date = changes[:computed_end_date]

    pre_service = %ServiceGap{gap: Datespan.strictly_before(computed_start_date),
                              reason: "before animal was put in service"
                             }
    spans = 
      if computed_end_date == :missing do
        [pre_service]
      else
        [ pre_service, %{
            gap: Datespan.date_and_after(computed_end_date),
            reason: "animal taken out of service"
          }
        ]        
      end

    put_change(changeset, :computed_service_gaps, spans)
  end

  def impossible_error_message, do: "has something unexpected wrong with it. Sorry."
  def no_names_error_message, do: "must have at least one valid name"
end
