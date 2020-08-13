defmodule CritBiz.ViewModels.Reservation.ShowTest do
  use Crit.DataCase
  alias CritBiz.ViewModels.Reservation.Show
  alias Crit.Reservations.ReservationApi
  alias Crit.Exemplars.ReservationFocused
  alias Pile.TimeHelper

  test "conversion" do
    ready = ReservationFocused.ready_to_reserve!(@bovine_id,
      ["jeff", "bossie"], ["procedure 1", "proc"])

    result =
      ready
      |> ReservationApi.create(@institution)
      |> ok_content
      |> Show.to_view_model(@institution)

    assert_fields(result,
      id: &is_integer/1,
      species_name: @bovine,
      timeslot_name: ReservationFocused.timeslot_name(),
      date: TimeHelper.date_string(ready.date), 
      animal_names: ["bossie", "jeff"],
      procedure_names: ["proc", "procedure 1"])
  end
end
