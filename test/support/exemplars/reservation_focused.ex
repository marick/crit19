defmodule Crit.Exemplars.ReservationFocused do
  use ExUnit.CaseTemplate
  use Crit.TestConstants
  alias Crit.Setup.Schemas.{Animal, Procedure}
  alias Crit.Sql
  alias Ecto.Datespan
  alias Crit.Setup.InstitutionApi
  alias CritWeb.Reservations.AfterTheFactStructs.State
  alias Crit.Reservations.ReservationApi
  import Ecto.Query
  import ExUnit.Assertions

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

  def morning_timeslot do
    hard_coded = 1
    assert InstitutionApi.timeslot_name(hard_coded, @institution) =~ "morning"
    hard_coded
  end

  def evening_timeslot do
    hard_coded = 3
    assert InstitutionApi.timeslot_name(hard_coded, @institution) =~ "evening"
    hard_coded
  end


  def timeslot_id do
    timeslot().id
  end

  def timeslot_name do
    timeslot().name
  end

  defp insert_or_create_x_ids(schema, inserter, names, species_id) do
    existing =
      (from x in schema, where: x.name in ^names)
      |> Sql.all(@institution)
    
    existing_ids = EnumX.ids(existing)
    existing_names = EnumX.names(existing)

    needed = Enum.reject(names, fn name ->
      Enum.member?(existing_names, name)
    end)

    new_ids = apply(__MODULE__, inserter, [needed, species_id])

    Enum.concat([existing_ids, new_ids])
  end

  defp insert_or_create_animal_ids(names, species_id),
    do: insert_or_create_x_ids(Animal, :inserted_animal_ids, names, species_id)
          
  defp insert_or_create_procedure_ids(names, species_id),
    do: insert_or_create_x_ids(Procedure, :inserted_procedure_ids, names, species_id)

  def ready_to_reserve!(species_id, animal_names, procedure_names, opts \\ []) do
    opts = Enum.into(opts, %{timeslot_id: timeslot_id(),
                             date: ~D[2019-01-01],
                             responsible_person: Faker.Name.name()})
    span = InstitutionApi.timespan(opts.date, opts.timeslot_id, @institution)

    animal_ids = insert_or_create_animal_ids(animal_names, species_id)
    procedure_ids = insert_or_create_procedure_ids(procedure_names, species_id)
    
    %State{
      species_id: species_id,
      timeslot_id: opts.timeslot_id,
      date: opts.date,
      span: span,
      responsible_person: opts.responsible_person,
      chosen_animal_ids: animal_ids,
      chosen_procedure_ids: procedure_ids
    }
  end

  def reserved!(species_id, animal_names, procedure_names, opts \\ []) do
    {:ok, reservation} = 
      ready_to_reserve!(species_id, animal_names, procedure_names, opts)
      |> ReservationApi.create(@institution)
    reservation
  end
end
