defmodule CritBiz.ViewModels.Reservation.Show do
  use Ecto.Schema
  alias Crit.Setup.InstitutionApi
  alias Crit.Schemas.Reservation
  alias Crit.Reservations.ReservationApi
  alias Pile.TimeHelper

  embedded_schema do
    field :species_name, :string
    field :date, :string
    field :timeslot_name, :id
    field :responsible_person, :string

    field :animal_names, {:array, :string}
    field :procedure_names, {:array, :string}
  end

  def to_view_model(%Reservation{} = r, institution) do 
    species_name = InstitutionApi.species_name(r.species_id, institution)
    timeslot_name = InstitutionApi.timeslot_name(r.timeslot_id, institution)
    {animal_names, procedure_names} = ReservationApi.all_names(r.id, institution)
    %__MODULE__{
      id: r.id,
      species_name: species_name, 
      date: TimeHelper.date_string(r.date),
      timeslot_name: timeslot_name,
      responsible_person: r.responsible_person,
      animal_names: animal_names,
      procedure_names: procedure_names
    }
  end
end
