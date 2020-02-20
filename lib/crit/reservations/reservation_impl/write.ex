defmodule Crit.Reservations.ReservationImpl.Write do
  alias Crit.Reservations.HiddenSchemas.Use
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Sql

  def create(struct, institution) do
    uses = 
      Use.cross_product(struct.chosen_animal_ids, struct.chosen_procedure_ids)
    
    attrs =
      Map.from_struct(struct)
      |> Map.put(:uses, uses)

    %Reservation{}
    |> Reservation.changeset(attrs)
    |> Sql.insert(institution)
  end  
end
