defmodule Crit.Reservations.ReservationApiTest do
  use Crit.DataCase
  # alias Crit.Reservations.Schemas.Reservation
  alias Crit.Reservations.ReservationApi
  alias Crit.Setup.InstitutionApi
  # alias Crit.Reservations.HiddenSchemas.Use
  # alias Crit.Sql
  # alias Ecto.Timespan
  alias Crit.Exemplars.ReservationFocused
  alias CritWeb.Reservations.AfterTheFactStructs.State

  describe "insertion" do
    test "we assume success" do 
      animal_ids =
        ReservationFocused.inserted_animal_ids(["Bossie", "jeff"], @bovine_id)
      procedure_ids =
        ReservationFocused.inserted_procedure_ids(
          ["procedure 1", "procedure 2"], @bovine_id)
      timeslot_id = ReservationFocused.a_timeslot_id
      span = InstitutionApi.timespan(@date_1, timeslot_id, @institution)

      params = %State{
        species_id: @bovine_id,
        timeslot_id: timeslot_id,
        span: span,
        chosen_animal_ids: animal_ids,
        chosen_procedure_ids: procedure_ids
      }

      ReservationApi.create(params, @institution)
      |> ok_payload
      |> assert_fields(species_id: @bovine_id,
#                       timeslot_id: timeslot_id,
                       span: span)
    end

  end

  #   @tag :skip
  #   test "success",
  #       %{params: params, animal_ids: animal_ids, procedure_ids: procedure_ids} do
  #     {:ok, %{id: id}} = ReservationApi.create(params, @institution)
  #     reservation = Sql.get(Reservation, id, @institution)

  #     expected_timespan =
  #       Timespan.from_date_time_and_duration(@start_date, @start_time, @minutes)
      
  #     assert reservation.timespan == expected_timespan
  #     assert reservation.species_id == @bovine_id

  #     # Check for valid uses
  #     uses = Sql.all(Use, @institution)
  #     assert length(uses) == 4
  #     assert one_use = List.first(uses)
      
  #     assert one_use.animal_id in animal_ids
  #     assert one_use.procedure_id in procedure_ids
  #     assert one_use.reservation_id == reservation.id
  #   end

  #   @tag :skip
  #   test "reservation entry: validation failure is transmitted", %{params:  params} do
  #     assert {:error, changeset} =
  #       params
  #       |> Map.put("species_id", "")
  #       |> ReservationApi.create(@institution)

  #     assert errors_on(changeset).species_id
  #   end

  #   @tag :skip
  #   test "reservation entry: species_id constraint failure should be impossible",
  #     %{params: params} do

  #     bad_params = Map.put(params, "species_id", "383838921")

  #     {:error, changeset} = ReservationApi.create(bad_params, @institution)
  #     assert errors_on(changeset).species_id
  #   end

  #   @tag :skip
  #   test "use: animal_id constraint failure is supposedly impossible", 
  #   %{params: params} do

  #     bad_params = Map.update!(params, "animal_ids",
  #       fn current -> Enum.concat(current, ["88383838"]) end)

  #     {:error, changeset} = ReservationApi.create(bad_params, @institution)

  #     refute changeset.valid?
  #     # Note that the error is buried within the changeset, not at the
  #     # top level. However, we don't report this error anyway because
  #     # it's impossible.
  #   end

  #   @tag :skip
  #   test "use: procedure_id constraint failure is supposedly impossible",
  #     %{params: params} do

  #     bad_params = Map.update!(params, "procedure_ids",
  #       fn current -> Enum.concat(current, ["88383838"]) end)

  #     {:error, changeset} = ReservationApi.create(bad_params, @institution)

  #     refute changeset.valid?
  #     # Note that the error is buried within the changeset, not at the
  #     # top level. However, we don't report this error anyway because
  #     # it's impossible.
  #   end
  # end
end
