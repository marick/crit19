defmodule Crit.Reservations.ReservationApi do 
  use Crit.Global.Constants
  alias Crit.Reservations.ReservationImpl.{Read,Write}
  alias Crit.Reservations.HiddenSchemas.{Use}
  # alias CritWeb.Reservations.AfterTheFactStructs.State

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

  def all_names(reservation_id, institution) do
    {animals, procedures} = all_used(reservation_id, institution)
    {Enum.map(animals, &(&1.name)),
     Enum.map(procedures, &(&1.name))}
  end

  def allowable_animals_after_the_fact(desired, institution) do
    Enum.concat(
      [Read.available(desired, institution),
       Read.rejected_at(:service_gap, desired, institution)])
    |> Enum.sort_by(&(&1.name))
  end
end
