defmodule Crit.Exemplars.ReservationFocused do
  use ExUnit.CaseTemplate
  use Crit.Global.Constants
  alias Crit.Setup.Schemas.{Animal, Procedure}
  alias Crit.Sql
  alias Ecto.Datespan
  alias Crit.Setup.InstitutionApi
  alias CritWeb.Reservations.AfterTheFactStructs.State

  defp named_thing_inserter(template) do 
    fn name ->
      template
      |> Map.put(:name, name)
      |> Sql.insert!(@institution)
    end
  end

  defp inserted_named_ids(names, template) do
    names
    |> Enum.map(named_thing_inserter template)
    |> EnumX.ids
  end

  # These are available for any reasonable reservation date.
  def inserted_animal_ids(names, species_id) do
    inserted_named_ids names, %Animal{
      species_id: species_id,
      span: Datespan.inclusive_up(~D[1990-01-01])
    }
  end

  def ignored_animal(name, species_id) do
    inserted_animal_ids([name], species_id)
    :ok
  end

  def inserted_procedure_ids(names, species_id) do
    inserted_named_ids names, %Procedure{species_id: species_id}
  end

  def ignored_procedure(name, species_id) do
    inserted_procedure_ids([name], species_id)
    :ok
  end

  def timeslot do
    InstitutionApi.timeslots(@institution)
    |> List.first
  end

  def timeslot_id do
    timeslot().id
  end

  def timeslot_name do
    timeslot().name
  end

  def ready_to_insert(species_id, animal_names, procedure_names, opts \\ []) do
    timeslot_id = Keyword.get(opts, :timeslot_id, timeslot_id())
    date = Keyword.get(opts, :date, ~D[2019-01-01])
    span = InstitutionApi.timespan(date, timeslot_id, @institution)

    animal_ids = inserted_animal_ids(animal_names, species_id)
    procedure_ids = inserted_procedure_ids(procedure_names, species_id)
    
    %State{
      species_id: species_id,
      timeslot_id: timeslot_id,
      date: date,
      span: span,
      chosen_animal_ids: animal_ids,
      chosen_procedure_ids: procedure_ids
    }
    
  end

  
  
end


