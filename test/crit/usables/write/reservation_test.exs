defmodule Crit.Usables.Write.ReservationTest do
  use Crit.DataCase
  alias Crit.Usables.Write
  alias Crit.Sql
  alias Ecto.Timespan

  @start_date_param "2019-11-12"
  @start_time_param "13:30:00"
  @minutes_param "90"
  @animal_ids_param ["1", "2", "3"]
  @procedure_ids_param ["11", "22", "33"]

  @start_date ~D[2019-11-12]
  @start_time ~T{13:30:00}
  @minutes 90
  @animal_ids [1, 2, 3]
  @procedure_ids [11, 22, 33]
  
  @params %{"start_date" => @start_date_param,
            "start_time" => @start_time_param,
            "minutes" => @minutes_param,
            "species_id" => @bovine_id,
            "animal_ids" => @animal_ids_param,
            "procedure_ids" => @procedure_ids_param,
  }
            

  describe "changeset" do
    test "required fields are checked" do
      errors =
        %Write.Reservation{}
        |> Write.Reservation.changeset(%{})
        |> errors_on

      assert errors.animal_ids
      assert errors.procedure_ids
      assert errors.start_date
      assert errors.start_time
      assert errors.minutes
      assert errors.species_id
    end

    test "appropriate conversions are done" do
      %{changes: changes} =
        %Write.Reservation{} |> Write.Reservation.changeset(@params)
      assert changes.start_date == @start_date
      assert changes.start_time == @start_time
      assert changes.minutes == @minutes
      assert changes.species_id == @bovine_id
      assert changes.animal_ids == @animal_ids
      assert changes.procedure_ids == @procedure_ids
    end
  end

  describe "insertion" do
    test "success" do
      {:ok, %{id: id}} = Write.Reservation.create(@params, @institution)
      fetched = Sql.get(Write.Reservation, id, @institution)

      expected_timespan =
        Timespan.from_date_time_and_duration(@start_date, @start_time, @minutes)
      
      assert fetched.timespan == expected_timespan
      assert fetched.species_id == @bovine_id
      assert fetched.animal_ids == @animal_ids
      assert fetched.procedure_ids == @procedure_ids
    end
  end
end
