defmodule Crit.Usables.ServiceGap do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Datespan
  alias Pile.TimeHelper

  @today "today"

  schema "service_gaps" do
    field :gap, Datespan
    field :reason, :string

    field :start_date, :string, virtual: true
    field :end_date, :string, virtual: true
    field :timezone, :string, virtual: true
  end


  defp changeset_for_date_field(field, attrs, today_getter) do 
    %__MODULE__{}
    |> cast(attrs,[field, :timezone])
    |> validate_required([field])
    |> convert_string_to_date_using(field, today_getter)
  end

  def pre_service_changeset(attrs, today_getter \\ &TimeHelper.today_date/1) do
    :start_date
    |> changeset_for_date_field(attrs, today_getter)
    |> put_gap(:infinite_down, :start_date, :exclusive)
    |> put_reason("before animal was put in service")
  end

  def post_service_changeset(attrs, today_getter \\ &TimeHelper.today_date/1) do
    :end_date
    |> changeset_for_date_field(attrs, today_getter)
    |> put_gap(:infinite_up, :end_date, :inclusive)
    |> put_reason("animal taken out of service")
  end

  def parse_message,
    do: "isn't a correct date. This should be impossible. Please report the problem."
  
  def convert_string_to_date_using(changeset, field, today_getter) do
    date_string = changeset.changes[field]
    case date_string == @today || Date.from_iso8601(date_string) do
      true ->
        timezone = changeset.changes.timezone
        today = today_getter.(timezone)
        put_change(changeset, field, today)
      {:ok, date} -> 
        put_change(changeset, field, date)
      {:error, _} ->
        add_error(changeset, field, parse_message())
    end
  end

  def put_reason(%{valid?: false} = changeset, _), do: changeset
  def put_reason(changeset, reason),
    do: put_change(changeset, :reason, reason)

  def put_gap(%{valid?: false} = changeset, _, _, _), do: changeset
  def put_gap(changeset, span_type, endpoint, exclusivity) do
    date = changeset.changes[endpoint]
    put_change(changeset, :gap, apply(Datespan, span_type, [date, exclusivity]))
  end
end

