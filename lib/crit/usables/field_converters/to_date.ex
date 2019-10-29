defmodule Crit.Usables.FieldConverters.ToDate do
  use Ecto.Schema
  use Crit.Global.Constants
  import Ecto.Changeset
  import Crit.Errors
  alias Pile.TimeHelper

  # Assumes this partial schema. Fields are constant because they come from
  # the domain.
  
  # field :in_service_datestring, :string
  # field :out_of_service_datestring, :string
  # field :timezone, :string
  
  # field :in_service_date, :date
  # field :out_of_service_date, :date

  def put_service_dates(changeset) do
    changeset
    |> put_in_service
    |> put_out_of_service
    |> check_date_order
  end

  def service_common(changeset, datestring, to) do 
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

  def put_in_service(changeset) do
    from = :in_service_datestring
    to = :in_service_date
    datestring = changeset.changes[from]
    case datestring == @today do
      true ->
        timezone = changeset.changes.timezone    
        today = TimeHelper.today_date(timezone)
        put_change(changeset, to, today)
      false ->
        service_common(changeset, datestring, to)
    end
  end

  def put_out_of_service(changeset) do
    from = :out_of_service_datestring
    to = :out_of_service_date
    datestring = changeset.changes[from]
    case datestring == @never do
      true -> 
        changeset
      false ->
        service_common(changeset, datestring, to)
    end
  end

  def check_date_order(changeset) do
    should_be_earlier = fetch_field!(changeset, :in_service_date)
    should_be_later = fetch_field!(changeset, :out_of_service_date)

    cond do
      should_be_later == nil -> 
        changeset
      Date.compare(should_be_earlier, should_be_later) == :lt ->
        changeset
      :else -> 
        add_error(changeset, :out_of_service_datestring, misorder_error_message())
    end      
  end

  def misorder_error_message, do: "should not be before the start date"
end  
