defmodule Crit.Usables.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Datespan
  alias Pile.TimeHelper

  @start_today "today"
  @end_never "never"

  schema "service_gaps" do
    field :gap, Datespan
    field :reason, :string

    field :start_date, :string, virtual: true
    field :end_date, :string, virtual: true
  end

  def pre_service_changeset(%__MODULE__{} = datespan, attrs \\ %{}) do
    datespan
    |> cast(attrs,[:start_date])
    |> validate_required([:start_date])
    |> cast_start
    |> put_reason("before animal was put in service")
    |> put_infinite_down(:exclusive)
  end

  def parse_message, do: "isn't a correct date. This should be impossible. Please report the problem."
  
  def cast_start(changeset) do
    date_string = changeset.changes.start_date
    case date_string == @start_today || Date.from_iso8601(date_string) do
      true ->
        today = TimeHelper.location_day(date_string, "America/Chicago")
        put_change(changeset, :start_date, today)
      {:ok, date} -> 
        put_change(changeset, :start_date, date)
      {:error, _} ->
        add_error(changeset, :start_date, parse_message())
    end
  end

  def put_reason(%{valid?: false} = changeset, _), do: changeset
  def put_reason(changeset, reason),
    do: put_change(changeset, :reason, reason)

  def put_infinite_down(%{valid?: false} = changeset, _), do: changeset
  def put_infinite_down(changeset, exclusivity) do
    start_date = changeset.changes.start_date
    put_change(changeset, :gap, Datespan.infinite_down(start_date, exclusivity))
  end
end

