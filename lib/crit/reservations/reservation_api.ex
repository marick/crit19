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
  
  def reservations_on_date(date, institution) do
    Read.by([date: date], institution)
  end

  def all_used(reservation_id, institution) do
    Use.all_used(reservation_id, institution)
  end
end
