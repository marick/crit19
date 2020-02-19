defmodule Crit.Reservations.ReservationApi do 
  use Crit.Global.Constants
  alias Crit.Reservations.ReservationImpl.{Write}
  # alias Crit.Reservations.Schemas.{Reservation}

  def create(struct, institution) do
    Write.create(struct, institution)
  end
  
end
