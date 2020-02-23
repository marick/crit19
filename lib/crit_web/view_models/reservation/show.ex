defmodule CritWeb.ViewModels.Reservation.Show do
  use Ecto.Schema
  alias Crit.Setup.InstitutionApi
  alias Crit.Reservations.Schemas.Reservation
  alias Crit.Reservations.ReservationApi
  alias Pile.TimeHelper

  embedded_schema do
    field :species_name, :string
    field :date, :string
    field :timeslot_name, :id

    field :animal_names, {:array, :string}
    field :procedure_names, {:array, :string}
  end

  def to_view_model(%Reservation{} = r, institution) do 
    species_name = InstitutionApi.species_name(r.species_id, institution)
    timeslot_name = InstitutionApi.timeslot_name(r.timeslot_id, institution)
    {animals, procedures} = ReservationApi.all_used(r.id, institution)
    %__MODULE__{
      id: r.id,
      species_name: species_name, 
      date: TimeHelper.date_string(r.date),
      timeslot_name: timeslot_name,
      animal_names: Enum.map(animals, &(&1.name)),
      procedure_names: Enum.map(procedures, &(&1.name))
    }
  end
end
