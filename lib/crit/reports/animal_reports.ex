defmodule Crit.Reports.AnimalReports do 
  use Crit.Global.Constants
  import Ecto.Query
  alias Crit.Sql
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Reservations.HiddenSchemas.Use
  alias Crit.Setup.Schemas.{Animal, Procedure}
  import Ecto.Timespan


  def use_rows(first_date, last_date, institution) do
    range = range(first_date, last_date)
    
    query = 
      from a in Animal, as: :animal,
      join: r in Reservation,
      join: u in Use,
      join: p in Procedure, as: :procedure,
      where: overlaps_fragment(r.span, ^range),
      where: u.reservation_id == r.id,
      where: u.procedure_id == p.id,
      where: u.animal_id == a.id

    query =
      from [animal: a, procedure: p] in query,
      group_by: [a.id, p.id],
      select: %{animal_name: a.name, animal_id: a.id,
                procedure_name: p.name, procedure_id: p.id,
                count: count(p.id)},
      order_by: [a.name, p.name]
    

    Sql.all(query, institution)
  end

  def structurize_uses(rows) do
    rows
    |> Enum.chunk_by(&(&1.animal_name))
    |> Enum.map(&structurize_animal_uses/1)
  end

  def structurize_animal_uses([first | _rest] = animal_uses) do
    procedure_summary = fn animal_use ->
      %{procedure: {animal_use.procedure_name, animal_use.procedure_id},
        count: animal_use.count}
    end
  
    %{animal: {first.animal_name, first.animal_id},
      procedures: Enum.map(animal_uses, procedure_summary)
     }
  end
    

  defp range(%Date{} = first_date, %Date{} = last_date) do 
    {:ok, range} =
      customary(first_date, Date.add(last_date, 1))
      |> dump
    range
  end
end
