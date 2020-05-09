defmodule Crit.Reservations.RestPeriodTest do
  use Crit.DataCase
  alias Crit.Reservations.RestPeriod
  alias Crit.Exemplars.{ReservationFocused,Available}
  alias Crit.Sql
  alias Crit.Setup.Schemas.{Animal}
  import DeepMerge

  def procedure_with_frequency(calculation_name) do
    frequency =
      Factory.sql_insert!(:procedure_frequency,
        name: calculation_name <> " frequency procedure",
        calculation_name: calculation_name)
    Factory.sql_insert!(:procedure,
      species_id: @bovine_id,
      frequency_id: frequency.id)
  end

  def existing_reservation do
    procedure = procedure_with_frequency("not used yet")
    bossie = Available.bovine("bossie")
    reservation = ReservationFocused.reserved!(@bovine_id,
      [bossie.name], [procedure.name], date: @date_2)
    [procedure: procedure, bossie: bossie, reservation: reservation]
  end    

  setup do
    existing_reservation()
  end

  test "foo", %{procedure: procedure, bossie: bossie, reservation: reservation} do
    Available.bovine("unused")

    animal_ids = [bossie.id]

    query =
      from a in Animal, where: a.id in ^animal_ids

    [actual] = 
      RestPeriod.conflicting_uses(query, "once per day", reservation.date, procedure.id)
      |> Sql.all(@institution)

    assert_fields(actual,
      animal_name: "bossie",
      procedure_name: procedure.name,
      date: @date_2)
  end


  # def simple_reservation(animal_name, kws) do
  #   parts = Enum.into(opts, %{})
  #   {procedure_name, procedure_opts} = part.for
  #   date = parts.on

  #   build_with(@bovine_id)
  #   |> procedure_frequency("frequency")
  #   |> procedure(procedure_name, procedure_opts)
  #   |> bovine(
    

  test "..." do
    arrange =
      build_with()
      |> procedure_frequency("once per day")
      |> procedures([ {"used procedure", frequency: "once per day"}, 
                      {"unused procedure", frequency: "once per day"}
                    ])
      |> bovine("leaky cow")
      |> reservation_for("vcm103", ["leaky cow"], ["used procedure"], date: @date_2)

    [act] =
      arrange
      |> t_conflicting_uses("once per day", @date_2, "used procedure")
      |> Sql.all(@institution)

    assert_fields(act,
      animal_name: "leaky cow",
      procedure_name: "used procedure",
      date: @date_2)
  end

  def t_conflicting_uses(data, frequency, date, procedure_name) do

    procedure_id = data[:procedure][procedure_name].id
    
    fetch_these_animals(data)
    |> RestPeriod.conflicting_uses(frequency, date, procedure_id)
  end

  def fetch_these_animals(data) do
    animal_ids = data[:animal] |> Map.values |> EnumX.ids

    from a in Animal, where: a.id in ^animal_ids
  end
  

  def build_with() do
    %{}
  end

  def procedure_frequency(data, calculation_name) do
    schema = :procedure_frequency
    
    addition = Factory.sql_insert!(schema,
      name: calculation_name <> " procedure frequency",
      calculation_name: calculation_name)

    deep_merge(data, %{schema => %{calculation_name => addition}})
  end

  def procedure(data, procedure_name, [frequency: frequency_name]) do 
    schema = :procedure

    frequency_id = data.procedure_frequency[frequency_name].id 

    addition = Factory.sql_insert!(schema,
      name: procedure_name,
      frequency_id: frequency_id)

    deep_merge(data, %{schema => %{procedure_name => addition}})
  end


  def procedures(data, descriptors) do
    Enum.reduce(descriptors, data, fn {key, opts}, acc ->
      apply &procedure/3, [acc, key, opts]
    end)
  end

  def animal(data, animal_name, species_id) do 
    schema = :animal

    addition = Factory.sql_insert!(schema,
      name: animal_name,
      species_id: species_id)

    deep_merge(data, %{schema => %{animal_name => addition}})
  end

  def bovine(data, animal_name), do: animal(data, animal_name, @bovine_id)


  def reservation_for(data, purpose, animal_names, procedure_names, opts \\ []) do
    schema = :reservation
    species_id = species_id(data, List.first(animal_names))
    
    addition =
      ReservationFocused.reserved!(species_id, animal_names, procedure_names, opts)

    deep_merge(data, %{schema => %{purpose => addition}})
  end


  def species_id(data, animal_name) do
    data[:animal][animal_name].species_id
  end
end
