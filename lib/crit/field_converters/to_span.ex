defmodule Crit.FieldConverters.ToSpan do
  use Ecto.Schema
  use Crit.Global.Constants
  use Crit.Errors
  import Ecto.Changeset
  alias Pile.TimeHelper
  alias Crit.Errors

  # Assumes this partial schema. Fields are constant because they come from
  # the domain.
  
  # field :in_service_datestring, :string
  # field :out_of_service_datestring, :string
  # field :timezone, :string
  
  # field :in_service_date, :date
  # field :out_of_service_date, :date

  def synthesize(changeset) do
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
          Errors.impossible_input("invalid date `#{datestring}`")
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
        add_error(changeset, :out_of_service_datestring, @date_misorder_message)
    end      
  end

  def note_misorder(changeset, field) do
    add_error(changeset, field, @date_misorder_message)
  end
end  
