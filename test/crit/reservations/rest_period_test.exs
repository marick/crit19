defmodule Crit.Reservations.RestPeriodTest do
  use Crit.DataCase
  import Crit.Exemplars.Background
  import Ecto.Query
  alias Crit.Reservations.RestPeriod
  alias Crit.Sql
  alias Crit.Setup.Schemas.{Animal}
  alias Crit.Sql

  @wednesday ~D[2020-06-17]
  @thursday  ~D[2020-06-18]
  @friday    ~D[2020-06-19]
  @saturday  ~D[2020-06-20]
  @sunday    ~D[2020-06-21]
  @monday    ~D[2020-06-22]
  @tuesday   ~D[2020-06-23]

  defp common_background(frequency) do 
    background(@bovine_id)
    |> procedure_frequency(frequency)
    |> procedure("used procedure", frequency: frequency)
    |> animal("bossie")
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

  defp attempt(existing, proposed, frequency) do 
    common_background(frequency)
    |> put_reservation(existing) 
    |> t_conflicting_uses(proposed)
  end

  def attempt(existing, proposed, frequency, :is_allowed) do
    attempt(existing, proposed, frequency) |> assert_empty
  end

  def attempt(existing, proposed, frequency, :is_refused) do
    attempt(existing, proposed, frequency) |> assert_conflict_on(existing)
  end


  #-----------------------------------------------------

  describe "constant width frequencies" do
    test "same day",
      do: attempt @friday, @friday,   "once per day", :is_refused
    
    test "previous day",
      do: attempt @friday, @thursday, "once per day", :is_allowed

    test "next day", 
      do: attempt @friday, @saturday, "once per day", :is_allowed
  end

  describe "once per week" do
    test "wednesday allows next wednesday",
      do: attempt @wednesday, Date.add(@wednesday, 7),   "once per week", :is_allowed
    
    test "wednesday allows previous wednesday",
      do: attempt @wednesday, Date.add(@wednesday, -7),   "once per week", :is_allowed
    
    test "wednesday prohibits previous thursday",
      do: attempt @wednesday, Date.add(@wednesday, -6),   "once per week", :is_refused
    
    test "wednesday prohibits next tuesday", 
      do: attempt @wednesday, Date.add(@wednesday, 6),   "once per week", :is_refused
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
      |> assert_conflict_on(@sunday)

      # and also on Sunday itself
      background
      |> t_conflicting_uses(@sunday)
      |> assert_conflict_on(@sunday)

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


  
  def assert_conflict_on(results, date) do
    results
    |> singleton_payload
    |> assert_fields(animal_name: "bossie",
                     procedure_name: "used procedure",
                     date: date)
  end

  def fetch_these_animals(data) do
    animal_ids = data[:animal] |> Map.values |> EnumX.ids

    from a in Animal, where: a.id in ^animal_ids
  end
  
  defp put_reservation(data, date) do
    data
    |> reservation_for("vcm103", ["bossie"], ["used procedure"], date: date)    
  end
  


end
