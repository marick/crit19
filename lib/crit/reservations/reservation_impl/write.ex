defmodule Crit.Reservations.ReservationImpl.Write do
  alias Crit.Reservations.HiddenSchemas.Use
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Sql

  def create(struct, institution) do
    struct_to_changeset(struct) |> Sql.insert(institution)
  end

  def create_noting_conflicts(struct, institution) do
    {:ok, result} = struct_to_changeset(struct) |> Sql.insert(institution)
    {:ok, result, %{service_gap: [], use: []}}
  end


  defp struct_to_changeset(struct) do
    uses = 
      Use.cross_product(struct.chosen_animal_ids, struct.chosen_procedure_ids)
    
    attrs =
      Map.from_struct(struct)
      |> Map.put(:uses, uses)

    Reservation.changeset(%Reservation{}, attrs)
  end
    
end
