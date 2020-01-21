defmodule CritWeb.Reservations.ReservationController.ReadTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.ReservationController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest

  setup :logged_in_as_reservation_manager

  test "recording an earlier use", %{conn: conn} do
    
    get_via_action(conn, :backdated_form)
    |> assert_purpose(record_a_use_that_was_not_prereserved())
  end
end
