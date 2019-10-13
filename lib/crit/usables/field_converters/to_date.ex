defmodule Crit.Usables.FieldConverters.ToDate do
  use Ecto.Schema
  use Crit.Global.Constants
  import Ecto.Changeset
  import Crit.Errors
  alias Pile.ChangesetFlow, as: Flow
  alias Pile.TimeHelper

  # Assumes this partial schema
  # field :start_date, :string
  # field :end_date, :string
  # field :timezone, :string
  
  # field :computed_start_date, :date, virtual: true
  # field :computed_end_date, :date, virtual: true
  

  def put_start_and_end(changeset) do
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

  defp check_date_order(changeset) do
    Flow.given_prerequisite_values_exist(changeset,
      [:computed_start_date, :computed_end_date],
      fn [should_be_earlier, should_be_later] ->
        if Date.compare(should_be_earlier, should_be_later) == :lt do
          changeset
        else
          add_error(changeset, :end_date, misorder_error_message())
        end      
      end)
  end

  defp compute_date(changeset, from, to) do
    date_string = changeset.changes[from]
    case date_string == @today || Date.from_iso8601(date_string) do
      true ->
        timezone = changeset.changes.timezone
        today = TimeHelper.today_date(timezone)
        put_change(changeset, to, today)
      {:ok, date} -> 
        put_change(changeset, to, date)
      {:error, _} ->
        impossible_input("invalid date `#{date_string}`")
    end
  end

  def misorder_error_message, do: "should not be before the start date"
end  