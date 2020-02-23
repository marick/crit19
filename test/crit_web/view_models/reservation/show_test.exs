defmodule CritWeb.ViewModels.Reservation.ShowTest do
  use Crit.DataCase
  alias Crit.ViewModels.Reservation.Show
  alias CritWeb.Reservations.AfterTheFactStructs.State
  alias Crit.Reservations.ReservationApi
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Setup.InstitutionApi


  @timeslot_id ReservationFocused.some_timeslot_id
  @timeslot_name InstitutionApi.timeslot_name(@timeslot_id, @institution)
  @span InstitutionApi.timespan(@date_1, @timeslot_id, @institution)
  @date ~D[2019-01-01]
  @human_date "January  1, 2019"

  def typical_params do 
    animal_ids =
      ReservationFocused.inserted_animal_ids(["Jeff", "bossie"], @bovine_id)
    procedure_ids =
      ReservationFocused.inserted_procedure_ids(
        ["procedure 1", "procedure 2"], @bovine_id)
    
    %State{
      species_id: @bovine_id,
      timeslot_id: @timeslot_id,
      date: @date,
      span: @span,
      chosen_animal_ids: animal_ids,
      chosen_procedure_ids: procedure_ids
    }
  end

  test "conversion" do
    result =
      typical_params()
      |> ReservationApi.create(@institution)
      |> ok_payload
      |> Show.to_view_model(@institution)

    assert_fields(result,
      id: &is_integer/1,
      species_name: @bovine,
      timeslot_name: @timeslot_name,
      date: @human_date, 
      animal_names: ["bossie", "Jeff"],
      procedure_names: ["procedure 1", "procedure 2"])
  end
end
