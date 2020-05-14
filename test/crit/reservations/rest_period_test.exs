defmodule Crit.Reservations.RestPeriodTest do
  use Crit.DataCase
  import Crit.Exemplars.Background
  import Ecto.Query
  alias Crit.Reservations.RestPeriod
  alias Crit.Sql
  alias Crit.Setup.Schemas.{Animal}
  alias Crit.Sql

  @sunday    ~D[2020-06-14]
  @monday    ~D[2020-06-15]
  @tuesday   ~D[2020-06-16]
  @wednesday ~D[2020-06-17]
  @thursday  ~D[2020-06-18]
  @friday    ~D[2020-06-19]
  @saturday  ~D[2020-06-20]

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
    test "Tuesday / Thursday is typical" do
      attempt @tuesday, @thursday, "twice per week", :is_allowed
    end

    test "adjacent days are not allowed" do
      attempt @tuesday, @wednesday, "twice per week", :is_refused
    end

    test "Monday / Wednesday / Friday is prohibited" do
      common_background("twice per week")
      |> put_reservation(@monday)
      |> put_reservation(@wednesday)
      
      |> t_conflicting_uses(@friday)
      
      |> singleton_payload
      |> assert_fields(animal_name: "bossie",
                       procedure_name: "used procedure",
                       dates: [@monday, @wednesday])
    end

    test "a different procedure on Wednesday won't prevent Friday" do
      # See previous test first.
      different = "different procedure"
      
      common_background("twice per week")
      |> put_reservation(@monday)

      |> procedure(different, frequency: "twice per week")
      |> reservation_for("vcm103",
              ["bossie"], [different], date: @wednesday)
      |> t_conflicting_uses(@friday)
      
      |> assert_empty
    end

    test "Week boundaries" do
      background = 
        common_background("twice per week")
        |> put_reservation(@monday)
        |> put_reservation(@wednesday)

      # Sunday is the beginning of the week.
      # (I know this is a myth programmers believe about time.)
      # This also tests what happens when there's a conflict
      # for two reasons. It's kind to show them both.
      [first_reason, second_reason] = 
        t_conflicting_uses(background, @sunday)

      assert_fields(first_reason,
        animal_name: "bossie",
        procedure_name: "used procedure",
        dates: [@monday])

      assert_fields(second_reason,
        animal_name: "bossie",
        procedure_name: "used procedure",
        dates: [@monday, @wednesday])

      # The day before sunday is in a new week.
      background
      |> t_conflicting_uses(Date.add(@sunday, -1))
      |> assert_empty

      # Saturday is the end of the week
      background
      |> t_conflicting_uses(@saturday)
      |> singleton_payload
      |> assert_fields(animal_name: "bossie",
                       procedure_name: "used procedure",
                       dates: [@monday, @wednesday])

      # Next sunday is next week
      background
      |> t_conflicting_uses(Date.add(@saturday, 1))
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
  
  def assert_conflict_on(results, dates) when is_list(dates) do
    results
    |> singleton_payload
    |> assert_fields(animal_name: "bossie",
                     procedure_name: "used procedure",
                     dates: dates)
  end

  def assert_conflict_on(results, date), do: assert_conflict_on(results, [date])
  

  def fetch_these_animals(data) do
    animal_ids = data[:animal] |> Map.values |> EnumX.ids

    from a in Animal, where: a.id in ^animal_ids
  end
  
  defp put_reservation(data, date) do
    data
    |> reservation_for("vcm103", ["bossie"], ["used procedure"], date: date)    
  end
  


end
