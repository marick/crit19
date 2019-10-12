defmodule Crit.Usables.Write.ReservationTest do
  use Crit.DataCase
  alias Crit.Usables.Reservation
  alias Crit.Usables.Hidden.Use
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
        %Reservation{}
        |> Reservation.changeset(%{})
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
        %Reservation{} |> Reservation.changeset(params)
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
      procedure_ids =
        ReservationFocused.inserted_procedure_ids(["1", "2"])

      params =
        @params
        |> Map.put("animal_ids", Enum.map(animal_ids, &to_string/1))
        |> Map.put("procedure_ids", Enum.map(procedure_ids, &to_string/1))
      [params: params, animal_ids: animal_ids, procedure_ids: procedure_ids]
    end


    test "success",
        %{params: params, animal_ids: animal_ids, procedure_ids: procedure_ids} do
      {:ok, %{id: id}} = Reservation.create(params, @institution)
      reservation = Sql.get(Reservation, id, @institution)

      expected_timespan =
        Timespan.from_date_time_and_duration(@start_date, @start_time, @minutes)
      
      assert reservation.timespan == expected_timespan
      assert reservation.species_id == @bovine_id

      # Check for valid uses
      uses = Sql.all(Use, @institution)
      assert length(uses) == 4
      assert one_use = List.first(uses)
      
      assert one_use.animal_id in animal_ids
      assert one_use.procedure_id in procedure_ids
      assert one_use.reservation_id == reservation.id
    end

    test "reservation entry: validation failure is transmitted", %{params:  params} do
      assert {:error, changeset} =
        params
        |> Map.put("species_id", "")
        |> Reservation.create(@institution)

      assert errors_on(changeset).species_id
    end
    
    test "reservation entry: species_id constraint failure should be impossible",
      %{params: params} do

      bad_params = Map.put(params, "species_id", "383838921")

      assert_raise Ecto.ConstraintError, fn -> 
        Reservation.create(bad_params, @institution)
      end
    end

    test "use: animal_id constraint failure is supposedly impossible", 
    %{params: params} do

      bad_params = Map.update!(params, "animal_ids",
        fn current -> Enum.concat(current, ["88383838"]) end)

      assert_raise RuntimeError, fn -> 
        Reservation.create(bad_params, @institution)
      end
    end

    test "use: procedure_id constraint failure is supposedly impossible",
      %{params: params} do

      bad_params = Map.update!(params, "procedure_ids",
        fn current -> Enum.concat(current, ["88383838"]) end)

      assert_raise RuntimeError, fn -> 
        Reservation.create(bad_params, @institution)
      end
    end
  end
end
