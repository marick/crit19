defmodule Crit.Reservations.ReservationImpl.ReadTest do
  use Crit.DataCase
  alias Crit.Setup.Schemas.{Animal}
  alias Crit.Reservations.ReservationImpl.Read
  alias Ecto.Datespan
  alias Crit.Exemplars.{Available, ReservationFocused}
  alias Ecto.Timespan
  alias Crit.Sql
  
  describe "animals that can be reserved" do
    # All tests seek available animals with the following characteristics
    # Note all the test values use @date_3 for the date
    @desired %{
      date: @date_3,
      species_id: @bovine_id,
      # Note that this overlaps the morning timeslot, so as to make sure
      # that the test is for overlap.
      span: Timespan.from_date_time_and_duration(@date_3, ~T[10:00:00.000], 240)
    }

    setup :animals_that_will_never_be_returned

    test "fetch animals in service" do
      Available.bovine("returned", @date_3)

      Read.in_service(@desired, @institution)
      |> assert_only("returned")
    end

    test "fetch animals with/without an overlapping service gap" do
      (rejected_name = "RETURNED by rejected_at")
      |> Available.bovine(@date_3)
      |> service_gap_including_desired_date!

      (available_name = "RETURNED by available")
      |> Available.bovine(@date_3)

      Read.Query.rejected_at(:service_gap, @desired) |> Sql.all(@institution)
      |> assert_only(rejected_name)

      Read.before_the_fact_animals(@desired, @institution)
      |> assert_only(available_name)
    end

    test "fetch animals with/without an overlapping use" do
      (rejected_name = "RETURNED by `rejected_at`")
      |> Available.bovine(@date_1)
      |> reserved_on_desired_date!(ReservationFocused.morning_timeslot)
        
      (available_name = "RETURNED by `available`")
      |> Available.bovine(@date_1)
      |> reserved_on_desired_date!(ReservationFocused.evening_timeslot)

      Read.Query.rejected_at(:uses, @desired) |> Sql.all(@institution)
      |> assert_only(rejected_name)

      Read.before_the_fact_animals(@desired, @institution)
      |> assert_only(available_name)
    end
  end
  
  def hard_unavailable_bovine!(name) do
    Factory.sql_insert!(:animal,
      [name: name,
       species_id: @bovine_id,
       span: Datespan.inclusive_up(@date_1),
       available: false],        # This is what makes it "hard"
      @institution)
  end

  def reserved_on_desired_date!(animal, timeslot_id) do
    ReservationFocused.reserved!(@bovine_id, [animal.name], ["procedure"],
      timeslot_id: timeslot_id,
      date: @date_3)
  end
  
  defp service_gap_including_desired_date!(animal),
    do: service_gap!(animal, Datespan.customary(@date_3, @date_4))
  
  def service_gap!(animal, span) do 
    Factory.sql_insert!(:service_gap, [animal_id: animal.id, span: span],
      @institution)
  end

  def assert_only(actual, name), 
    do: assert [%Animal{name: ^name}] = actual


  defp animals_that_will_never_be_returned(_) do 
    Available.bovine("NEVER RETURNED: not in service yet", @date_7)
    Available.bovine("NEVER RETURNED: desired is past out of service date",
      Datespan.customary(@date_1, @date_2))
    
    # `animal.available == false`
    hard_unavailable_bovine!("NEVER RETURNED: marked 'hard' unavailable")
    
    # This checks that a service gap doesn't cause an
    # `animal.available == false` animal to be returned.
    hard_unavailable_bovine!(
      "NEVER RETURNED: 'hard' unavailable + matching sg")
      |> service_gap_including_desired_date!
    
    Available.equine("NEVER RETURNED: wrong species", @date_3)
    |> service_gap_including_desired_date!
    
    :ok
  end    
end
