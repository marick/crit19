defmodule Crit.Reservations.RestPeriodTabularTest do
  use Crit.DataCase
  import Crit.RepoState
  alias Crit.Reservations.RestPeriod
  import FlowAssertions.Checkers

  @sun    ~D[2020-06-14]
  @mon    ~D[2020-06-15]
  @tue   ~D[2020-06-16]
  @wed ~D[2020-06-17]
  @thu  ~D[2020-06-18]
  @fri    ~D[2020-06-19]
  @sat  ~D[2020-06-20]

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
  
  def make_runners(background_populator, animal_name, procedure_name) do 
    populate = fn dates ->
      repo = background_populator.()
      Enum.reduce(dates, repo, fn date, acc ->
        reservation_for(acc, Factory.unique("reservation"),
          [animal_name], [procedure_name],
          date: date)
      end)
    end

    run = fn dates ->
      {:error, retval} = 
        Crit.Repo.transaction(fn -> 
          {previous, [then: next]} = Enum.split(dates, -1)
          populate.(previous)
          |> conflicts_for(next)
          |> Crit.Repo.rollback
        end)
      retval
    end

    ok = fn dates ->
      assert run.(dates) == []
    end


    assert_date_list_in_results = fn all_results, dates -> 
      pass =
        Enum.any?(all_results, fn result ->
          result.animal_name == animal_name &&
            result.procedure_name == procedure_name &&
            good_enough?(result.dates, in_any_order(dates))
        end)
      assert(pass)
    end

    error_mentions = fn reservation_dates, error_dates ->
      results = run.(reservation_dates)
      assert_date_list_in_results.(results, error_dates)
      
    end

    plus = fn results, error_dates ->
      assert_date_list_in_results.(results, error_dates)
      results
    end

#      IO.inspect {error_dates, results}
      # |> assert_field(animal_name: animal_name,
      #                 procedure_name: procedure_name,
      #                 dates: in_any_order(error_dates))

    %{populate: populate, run: run, ok: ok, error_mentions: error_mentions, plus: plus}
  end
  


  test "twice-per-week frequency" do
    background = fn -> 
      empty_repo()
      |> procedure("haltering", frequency: "twice per week")
    end
    
    a = make_runners(background, "bossie", "haltering")

    # # Days may not be adjacent
    # [@tue, then: @thu] |> a.ok.()   # this is the most typical schedule
    # [@thu, then: @tue] |> a.ok.()   # order doesn't matter.
    # [@tue, then: @wed] |> a.error_mentions.([@tue])

    # # the total number of days reserved in the week also counts
    # [@mon, @wed, then: @fri]  |> a.error_mentions.([@mon, @wed])

    # # Both can apply. (In target market, Sunday is the first day of the week)
    [@mon, @wed, then: @sun]  |> a.error_mentions.([@mon])       # adjacent day
                              |>           a.plus.([@mon, @wed])  # three times / week

    # ...
  end  
end
