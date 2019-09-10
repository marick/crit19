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

  def changeset(%__MODULE__{} = datespan, attrs \\ %{}) do
    datespan
    |> cast(attrs, [:reason, :start_date, :end_date])
    |> validate_required([:reason, :start_date, :end_date])
    |> cast_start
    |> cast_end
    |> validate_order
    |> put_gap
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

  def cast_end(changeset) do
    date_string = changeset.changes.end_date
    case date_string == @end_never || Date.from_iso8601(date_string) do
      true ->
        changeset
      {:ok, date} -> 
        put_change(changeset, :end_date, date)
      {:error, _} ->
        add_error(changeset, :end_date, parse_message())
    end
  end

  def order_message, do: "should be before the end date"

  def validate_order(changeset) do
    start_date = changeset.changes.start_date
    end_date = changeset.changes.end_date
    cond do
      !changeset.valid? ->
        changeset
      end_date == @end_never ->
        changeset
      Date.compare(start_date, end_date) == :lt -> 
        changeset
      true ->
        add_error(changeset, :start_date, order_message())
      end
  end

  def put_gap(changeset) do
    start_date = changeset.changes.start_date
    end_date = changeset.changes.end_date
    case {changeset.valid?, end_date} do
      {true, @end_never} ->
        put_change(changeset, :gap, Datespan.infinite_up(start_date, :inclusive))
      {true, _} -> 
        put_change(changeset, :gap, Datespan.customary(start_date, end_date))
      {false, _} ->
        changeset
    end
  end
end

