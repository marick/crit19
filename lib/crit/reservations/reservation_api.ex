defmodule Crit.Reservations.ReservationApi do 
  use Crit.Global.Constants
  alias Crit.Reservations.ReservationImpl.{Read,Write}
  alias Crit.Reservations.HiddenSchemas.{Use}

  def create(struct, institution) do
    case Write.create(struct, institution) do 
      {:ok, reservation} -> 
        {:ok, Read.put_updatable_fields(reservation, institution)}
    end
  end

  def get!(id, institution) do
    Read.by_id(id, institution)
  end
  
  def updatable!(id, institution) do
    Read.by_id(id, institution)
    |> Read.put_updatable_fields(institution)
  end

  def reservations_on_date(date, institution) do
    Read.by([date: date], institution)
    |> Enum.map(&(Read.put_updatable_fields(&1, institution)))
  end

  def all_used(reservation_id, institution) do
    Use.all_used(reservation_id, institution)
  end
end
