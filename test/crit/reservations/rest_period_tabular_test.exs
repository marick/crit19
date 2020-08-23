defmodule Crit.Reservations.RestPeriodTabularTest do
  use Crit.DataCase
  import Crit.RepoState
  alias Crit.Reservations.RestPeriod
  import FlowAssertions.Checkers

#  @sun    ~D[2020-06-14]
  @mon    ~D[2020-06-15]
  @tue   ~D[2020-06-16]
  @wed ~D[2020-06-17]
#  @thu  ~D[2020-06-18]
#  @fri    ~D[2020-06-19]
#  @sat  ~D[2020-06-20]

  #-----------------------------------------------------



  def t_unavailable_by(data, date) do
    RestPeriod.unavailable_by("ignored",
      %{chosen_animal_ids: data[:animal] |> Map.values |> EnumX.ids,
       chosen_procedure_ids: data[:procedure] |> Map.values |> EnumX.ids,
       date: date}, 
      @institution)
  end

  def conflicts_for(repo, date) do
    t_unavailable_by(repo, date)
  end
  

  
  

  test "linear" do 
    repo = 
      empty_repo()
      |> procedure("haltering", frequency: "twice per week")
      |> reservation_for("vcm103", ["bossie"], ["haltering"], date: @mon)

    conflicts_for(repo, @tue)
    |> singleton_content
    |> assert_fields(animal_name: "bossie",
                     procedure_name: "haltering",
                     dates: [@mon])
  end
  
  def maker(repo, animal_name, procedure_name) do 
    populate = fn dates ->
      Enum.reduce(dates, repo, fn date, acc ->
        reservation_for(acc, Factory.unique("reservation"),
          [animal_name], [procedure_name],
          date: date)
      end)
    end

    run = fn dates -> 
      {previous, [then: next]} = Enum.split(dates, -1)
      populate.(previous)
      |> conflicts_for(next)
    end

    ok = fn dates ->
      assert run.(dates) == []
    end

    error = fn reservation_dates, error_dates ->
      run.(reservation_dates)
      |> singleton_content
      |> assert_field(animal_name: animal_name,
                      procedure_name: procedure_name,
                      dates: in_any_order(error_dates))
        
        
    end

    %{populate: populate, run: run, ok: ok, error: error}
  end

      

  test "tabular" do
    
    a = 
      empty_repo()
      |> procedure("haltering", frequency: "twice per week")
      |> maker("bossie", "haltering")

    [@tue, then: @wed] |> a.error.([@tue])

    # # Days may not be adjacent
    # [@tue, then: @thu] |> a.ok()   # this is the most typical schedule
    # [@thu, then: @tue] |> a.ok()   # order doesn't matter.
    # [@tue, then: @wed] |> a.error([@tue])

    # # the total number of days reserved in the week also counts
    # [@mon, @wed, then: @fri]  |> a.error([@mon, @wed])

    # # Both can apply. (In target market, Sunday is the first day of the week)
    # [@mon, @wed, then: @sun]  |> a.error([@mon])        # adjacent day
    #                           |> a.error([@mon, @wed])  # three times / week

    # ...
  end
end
