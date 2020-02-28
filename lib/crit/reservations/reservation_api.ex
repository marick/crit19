defmodule Crit.Reservations.ReservationApi do 
  use Crit.Global.Constants
  alias Crit.Reservations.ReservationImpl.{Read,Write}
  alias Crit.Reservations.HiddenSchemas.{Use}

  def create(struct, institution) do
    Write.create(struct, institution)
  end

  def get!(id, institution) do
    Read.by_id(id, institution)
  end

  def on_date(date, institution), do: on_dates(date, date, institution)
  
  def on_dates(inclusive_start, inclusive_end, institution) do
    Read.on_dates(inclusive_start, inclusive_end, institution)
  end

  def all_used(reservation_id, institution) do
    Use.all_used(reservation_id, institution)
  end
end
