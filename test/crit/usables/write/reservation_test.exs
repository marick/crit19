defmodule Crit.Usables.Write.ReservationTest do
  use Crit.DataCase
  alias Crit.Usables.Write
  alias Crit.Sql
  alias Ecto.Timespan
  alias Crit.Exemplars.ReservationFocused

  @start_date_param "2019-11-12"
  @start_time_param "13:30:00"
  @minutes_param "90"

  @start_date ~D[2019-11-12]
  @start_time ~T{13:30:00}
  @minutes 90
  
  @params %{"start_date" => @start_date_param,
            "start_time" => @start_time_param,
            "minutes" => @minutes_param,
            "species_id" => @bovine_id,
  }
            

  describe "changeset" do
    test "required fields are checked" do
      errors =
        %Write.Reservation{}
        |> Write.Reservation.changeset(%{})
        |> errors_on

      assert errors.start_date
      assert errors.start_time
      assert errors.minutes
      assert errors.species_id
      assert errors.animal_ids
      assert errors.procedure_ids
    end

    test "appropriate conversions are done" do
      params =
        @params
        |> Map.put("animal_ids", ["1", "2", "3"])
        |> Map.put("procedure_ids", ["11", "22", "33"])
      %{changes: changes} =
        %Write.Reservation{} |> Write.Reservation.changeset(params)
      assert changes.start_date == @start_date
      assert changes.start_time == @start_time
      assert changes.minutes == @minutes
      assert changes.species_id == @bovine_id
      assert changes.animal_ids == [1, 2, 3]
      assert changes.procedure_ids == [11, 22, 33]
    end
  end

  describe "insertion" do
    setup do
      animal_ids =
        ReservationFocused.inserted_animal_ids(["Bossie", "jeff"], @bovine_id)
        |> Enum.map(&to_string/1)
      procedure_ids =
        ReservationFocused.inserted_procedure_ids(["1", "2"])
        |> Enum.map(&to_string/1)

      params =
        @params
        |> Map.put("animal_ids", animal_ids)
        |> Map.put("procedure_ids", procedure_ids)
      [params: params]
    end


    test "success", %{params: params} do
      {:ok, %{id: id}} = Write.Reservation.create(params, @institution)
      fetched = Sql.get(Write.Reservation, id, @institution)

      expected_timespan =
        Timespan.from_date_time_and_duration(@start_date, @start_time, @minutes)
      
      assert fetched.timespan == expected_timespan
      assert fetched.species_id == @bovine_id
    end

    test "reservation entry: validation failure is transmitted", %{params:  params} do
      assert {:error, changeset} =
        params
        |> Map.put("species_id", "")
        |> Write.Reservation.create(@institution)

      assert errors_on(changeset).species_id
    end
    
    @tag :skip
    test "reservation entry: species_id constraint failure is transmitted" do
    end

    @tag :skip
    test "use: animal_id constraint failure is transmitted" do
    end

    @tag :skip
    test "use: procedure_id constraint failure is transmitted" do
    end
  end
end
