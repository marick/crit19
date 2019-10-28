defmodule Crit.Usables.FieldConverters.ToDate do
  use Ecto.Schema
  use Crit.Global.Constants
  import Ecto.Changeset
  import Crit.Errors
  alias Pile.ChangesetFlow, as: Flow
  alias Pile.TimeHelper

  # Assumes this partial schema. Fields are constant because they come from
  # the domain.
  
  # field :in_service_datestring, :string
  # field :out_of_service_datestring, :string
  # field :timezone, :string
  
  # field :in_service_date, :date
  # field :out_of_service_date, :date

  def put_service_dates__2(changeset) do
    changeset
    |> put_in_service__2
    |> put_out_of_service__2
    |> check_date_order__2
  end

  def service_common__2(changeset, datestring, to) do 
    if datestring == nil do 
      changeset
    else
      case Date.from_iso8601(datestring) do
        {:ok, date} ->
          put_change(changeset, to, date)
        {:error, _} -> 
          impossible_input("invalid date `#{datestring}`")
      end
    end
  end

  def put_in_service__2(changeset) do
    from = :in_service_datestring
    to = :in_service_date
    datestring = changeset.changes[from]
    case datestring == @today do
      true ->
        timezone = changeset.changes.timezone    
        today = TimeHelper.today_date(timezone)
        put_change(changeset, to, today)
      false ->
        service_common__2(changeset, datestring, to)
    end
  end

  def put_out_of_service__2(changeset) do
    from = :out_of_service_datestring
    to = :out_of_service_date
    datestring = changeset.changes[from]
    case datestring == @never do
      true -> 
        changeset
      false ->
        service_common__2(changeset, datestring, to)
    end
  end

  def check_date_order__2(changeset) do
    should_be_earlier = fetch_field!(changeset, :in_service_date)
    should_be_later = fetch_field!(changeset, :out_of_service_date)
    if Date.compare(should_be_earlier, should_be_later) == :lt do
      changeset
    else
      add_error(changeset, :out_of_service_datestring, misorder_error_message())
    end      
  end
  
  

  

  def put_service_dates(changeset) do
    with_start = compute_date(changeset, :in_service_datestring, :in_service_date)

    if changeset.changes.out_of_service_datestring == @never do
      # this value is allowed to be NULL in the database
      with_start
    else
      with_start
      |> compute_date(:out_of_service_datestring, :out_of_service_date)
      |> check_date_order
    end
  end

  defp check_date_order(changeset) do
    Flow.given_prerequisite_values_exist(changeset,
      [:in_service_date, :out_of_service_date],
      fn [should_be_earlier, should_be_later] ->
        if Date.compare(should_be_earlier, should_be_later) == :lt do
          changeset
        else
          add_error(changeset, :out_of_service_datestring, misorder_error_message())
        end      
      end)
  end

  defp compute_date(changeset, from, to) do
    datestring = changeset.changes[from]
    case datestring == @today || Date.from_iso8601(datestring) do
      true ->
        timezone = changeset.changes.timezone
        today = TimeHelper.today_date(timezone)
        put_change(changeset, to, today)
      {:ok, date} -> 
        put_change(changeset, to, date)
      {:error, _} ->
        impossible_input("invalid date `#{datestring}`")
    end
  end

  def misorder_error_message, do: "should not be before the start date"
end  
