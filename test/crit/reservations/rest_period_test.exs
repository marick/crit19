defmodule Crit.Reservations.RestPeriodTest do
  use Crit.DataCase
  alias Crit.Reservations.RestPeriod
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Sql
  alias Crit.Setup.Schemas.{Animal}
  import DeepMerge

  @thursday ~D[2020-06-18]
  @friday   ~D[2020-06-19]
  @saturday ~D[2020-06-20]
  @sunday   ~D[2020-06-21]
  @monday   ~D[2020-06-22]
  @tuesday  ~D[2020-06-23]

  setup do # animal and procedure
    background = 
      background(@bovine_id)
      |> procedure_frequency("once per day")
      |> procedure("used procedure", frequency: "once per day")
      |> animal("bossie")
    [background: background]
  end    

  describe "once per day" do
    setup(%{background: background}) do
      background =
        background
        |> reservation_for("vcm103", ["bossie"], ["used procedure"], date: @friday)

      [background: background]
    end
    
    test "can't make another reservation on the same day",
      %{background: background} do
      background
      |> t_conflicting_uses(@friday)
      |> assert_conflicting_reservation_on(@friday)
    end
    
    test "can make a reservation on the previous day",
      %{background: background} do
      background 
      |> t_conflicting_uses(@thursday)
      |> assert_empty
    end

    test "can make a reservation on the next day",
      %{background: background} do
      
      background 
      |> t_conflicting_uses(@saturday)
      |> assert_empty
    end
  end

  describe "once per week" do
    @tag :skip
    test "wednesday allows next wednesday", %{background: _background} do
    end
    
    @tag :skip
    test "wednesday allows previous wednesday", %{background: _background} do
    end
    
    @tag :skip
    test "wednesday prohibits previous thursday", %{background: _background} do
    end
    
    @tag :skip
    test "wednesday prohibits next tuesday", %{background: _background} do
    end
  end



  describe "twice per week" do
    @tag :skip
    test "Tuesday / Thursday is typical" do
    end

    @tag :skip
    test "Monday / Wednesday / Friday is prohibited" do
    end

    @tag :skip
    test "adjoining days are prohibited",
      %{background: background} do

      background =
        background
        |> reservation_for("vcm103", ["bossie"], ["used procedure"], date: @sunday)

      background
      |> t_conflicting_uses(@monday)
      |> assert_conflicting_reservation_on(@sunday)

      # and also on Sunday itself
      background
      |> t_conflicting_uses(@sunday)
      |> assert_conflicting_reservation_on(@sunday)

      # But a Tuesday reservation is allowed
      background
      |> t_conflicting_uses(@tuesday)
      |> assert_empty

      # ... and a saturday
      background
      |> t_conflicting_uses(@saturday)
      |> assert_empty
    end
  end

  describe "the unlimited frequency" do
    @tag :skip
    test "it never returns a conflict" do
      # This demonstrates that it doesn't return non-frequency conflicts"
    end
    
    @tag :skip
    test "it does not touch the database"
  end



  describe "facts that apply to any of the frequencies (except 'unlimited')" do
    @tag :skip
    test "doesn't return procedures not mentioned in the proposed reservation"


    @tag :skip
    test "not fooled by animal of animal of a different species"

    @tag :skip
    test "will return more than one conflict for the same animal"
  end


  
  def assert_conflicting_reservation_on(results, date) do
    results
    |> singleton_payload
    |> assert_fields(animal_name: "bossie",
                     procedure_name: "used procedure",
                     date: date)
  end


  def t_conflicting_uses(data, date) do

    procedure_id = data[:procedure]["used procedure"].id
    frequency =
      data[:procedure_frequency]
      |> Map.keys
      |> List.first
    
    fetch_these_animals(data)
    |> RestPeriod.conflicting_uses(frequency, date, procedure_id)
    |> Sql.all(@institution)
  end

  def fetch_these_animals(data) do
    animal_ids = data[:animal] |> Map.values |> EnumX.ids

    from a in Animal, where: a.id in ^animal_ids
  end
  

  def background(species_id) do
    %{species_id: species_id}
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
    species_id = data.species_id

    addition = Factory.sql_insert!(schema,
      name: procedure_name,
      species_id: species_id,
      frequency_id: frequency_id)

    deep_merge(data, %{schema => %{procedure_name => addition}})
  end


  def procedures(data, descriptors) do
    Enum.reduce(descriptors, data, fn {key, opts}, acc ->
      apply &procedure/3, [acc, key, opts]
    end)
  end

  def animal(data, animal_name) do 
    schema = :animal

    addition = Factory.sql_insert!(schema,
      name: animal_name,
      species_id: data.species_id)

    deep_merge(data, %{schema => %{animal_name => addition}})
  end

  def reservation_for(data, purpose, animal_names, procedure_names, opts \\ []) do
    schema = :reservation
    species_id = data.species_id
    
    addition =
      ReservationFocused.reserved!(species_id, animal_names, procedure_names, opts)

    deep_merge(data, %{schema => %{purpose => addition}})
  end
end
