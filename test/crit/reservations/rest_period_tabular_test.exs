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
  # @sat  ~D[2020-06-20]

  #-----------------------------------------------------

  def conflicts_for(repo, date) do
    RestPeriod.unavailable_by(
      %{chosen_animal_ids: repo[:__schemas__][:animal] |> Map.values |> EnumX.ids,
        chosen_procedure_ids: repo[:__schemas__][:procedure] |> Map.values |> EnumX.ids,
        date: date}, 
      @institution)
  end
  
  describe "twice per week frequency: linear tests" do
    setup do
      repo = 
        empty_repo()
        |> procedure("haltering", frequency: "twice per week")
      [repo: repo]
    end

    test "third day is rejected", %{repo: repo} do
      # Arrange
      repo
      |> reservation_for(["bossie"], ["haltering"], date: @wed)
      |> reservation_for(["bossie"], ["haltering"], date: @mon)

      # Act
      |> conflicts_for(                              @fri)

      # Assert
      |> singleton_content
      |> assert_fields(animal_name:    "bossie",
                       procedure_name: "haltering",
                       dates:          in_any_order([@mon, @wed]))
    end
  end


  
  def reservations_will_use(background_populator, animal_name, procedure_name) do 
    populate = fn dates ->
      repo = background_populator.()
      Enum.reduce(dates, repo, fn date, acc ->
        reservation_for(acc,
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
      all_results
    end

    error_mentions = fn reservation_dates, error_dates ->
      results = run.(reservation_dates)
      assert_date_list_in_results.(results, error_dates)
    end

    plus = fn results, error_dates ->
      assert_date_list_in_results.(results, error_dates)
    end

    %{ok: ok, error_mentions: error_mentions, plus: plus}
  end

  describe "a twice-per-week frequency" do
    setup do
      runners = 
        fn -> 
          empty_repo()
          |> animal("bossie")
          |> procedure("haltering", frequency: "twice per week")
      end
      |> reservations_will_use("bossie", "haltering")

      [a: runners]
    end

    test "a typical twice-a-week schedule", %{a: a} do 
      [@tue, then: @thu] |> a.ok.()
      [@thu, then: @tue] |> a.ok.()   # order doesn't matter.
    end
    
    test "a third day in the week is disallowed", %{a: a} do 
      [@mon, @wed, then: @fri]  |> a.error_mentions.([@mon, @wed])
    end

    test "adjacent dates are disallowed, no matter if only two in week", %{a: a} do
      [@tue, then: @wed] |> a.error_mentions.([@tue])
    end

    test "in target market, sunday is the first day of the week", %{a: a} do
      [@mon, then: @sun] |> a.error_mentions.([@mon])
    end
    
    test "A single attempt can fail for two reasons", %{a: a} do 
      [@mon, @wed, then: @sun]  |> a.error_mentions.([@mon])       # adjacent day
                                |>           a.plus.([@mon, @wed]) # three times / week
    end 
  end  
end
