defmodule Crit.Usables.Write.BulkAnimal do
  use Ecto.Schema
  import Ecto.Changeset
  alias Crit.Ecto.{NameList}
  alias Pile.TimeHelper
  alias Ecto.Datespan
  alias Crit.Usables.ServiceGap


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
        add_error(changeset, :names, no_names_error_message())
      {:ok, namelist} -> 
        put_change(changeset, :computed_names, namelist)
      _ -> 
        add_error(changeset, :names, impossible_error_message())
    end
  end

  @today "today"
  @never "never"



  def compute_dates(changeset) do
    with_start = compute_date(changeset, :start_date, :computed_start_date)

    if changeset.changes.end_date == @never do
      with_start
      |> put_change(:computed_end_date, :missing)
    else
      with_start
      |> compute_date(:end_date, :computed_end_date)
      |> check_date_order
    end
  end

  def check_date_order(%{changes: changes} = changeset) do
    case {changes[:computed_start_date], changes[:computed_end_date]} do
      {nil, _} -> changeset
      {_, nil} -> changeset
      {to_be_earlier, to_be_later} ->
        if Date.compare(to_be_earlier, to_be_later) == :lt do
          changeset
        else
          add_error(changeset, :end_date, misorder_error_message())
        end      
    end
  end

  def compute_date(changeset, from, to) do
    date_string = changeset.changes[from]
    case date_string == @today || Date.from_iso8601(date_string) do
      true ->
        timezone = changeset.changes.timezone
        today = TimeHelper.today_date(timezone)
        put_change(changeset, to, today)
      {:ok, date} -> 
        put_change(changeset, to, date)
      {:error, _} ->
        add_error(changeset, from, parse_error_message())
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

  def parse_error_message,
    do: "isn't a correct date. This should be impossible. Please report the problem."
  def impossible_error_message, do: "has something unexpected wrong with it. Sorry."
  def no_names_error_message, do: "must have at least one valid name"
  def misorder_error_message, do: "should not be before the start date"

end
