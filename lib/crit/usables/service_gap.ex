defmodule Crit.Usables.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Datespan
  alias Pile.TimeHelper

  @today "today"
  @never "never"

  schema "service_gaps" do
    field :gap, Datespan
    field :reason, :string

    field :start_date, :string, virtual: true
    field :end_date, :string, virtual: true
    field :timezone, :string, virtual: true
  end

  def pre_service_changeset(attrs, today_getter \\ &TimeHelper.today_date/1) do
    %__MODULE__{}
    |> cast(attrs,[:start_date, :timezone])
    |> validate_required([:start_date])
    |> convert_start_to_date_using(today_getter)
    |> put_infinite_down(:exclusive)
    |> put_reason("before animal was put in service")
  end

  def parse_message,
    do: "isn't a correct date. This should be impossible. Please report the problem."
  
  def convert_start_to_date_using(changeset, today_getter) do
    date_string = changeset.changes.start_date
    case date_string == @today || Date.from_iso8601(date_string) do
      true ->
        timezone = changeset.changes.timezone
        today = today_getter.(timezone)
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

