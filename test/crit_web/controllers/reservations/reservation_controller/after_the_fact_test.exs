defmodule CritWeb.Reservations.ReservationController.AfterTheFactTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.ReservationController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest

  setup :logged_in_as_reservation_manager

  describe "recording an earlier use" do
    test "the first form", %{conn: conn} do
      get_via_action(conn, :after_the_fact_form_1)
      |> assert_purpose(after_the_fact_pick_species_and_time())
    end
  end
end
