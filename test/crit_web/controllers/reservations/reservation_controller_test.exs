defmodule CritWeb.Reservations.ReservationControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.ReservationController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Setup.InstitutionApi
  alias CritWeb.ViewModels.Reservation.CalendarEntry

  setup :logged_in_as_reservation_manager

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end
  
  describe "week_data" do
    test "empty", %{conn: conn} do
      conn = get_via_action(conn, :week_data)
      
      assert json_response(conn, 200)["data"] == []
    end

    test "a reservation", %{conn: conn} do 
      reservation = ReservationFocused.reserved!(@bovine_id,
        ["jeff", "bossie"], ["procedure 1", "proc"],
        date: InstitutionApi.today!(@institution))

      assert [result] =
        get_via_action(conn, :week_data)
        |> json_response(200)
        |> Map.get("data")

      # The details of the output are in the CalendarEntry tests.
      assert result["body"] == CalendarEntry.to_map(reservation, @institution).body
    end
  end
end
