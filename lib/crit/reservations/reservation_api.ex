defmodule Crit.Reservations.ReservationApi do 
  use Crit.Global.Constants
  alias Crit.Reservations.ReservationImpl.{Read,Write}
  # alias Crit.Reservations.Schemas.{Reservation}

  def create(struct, institution) do
    case Write.create(struct, institution) do 
      {:ok, reservation} -> 
        {:ok, Read.put_updatable_fields(reservation, institution)}
    end
  end

  def updatable!(id, institution) do
    Read.by_id(id, institution)
    |> Read.put_updatable_fields(institution)
  end

  def reservations_on_date(date, institution) do
  end
end
