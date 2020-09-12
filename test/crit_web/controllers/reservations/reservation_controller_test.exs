defmodule CritWeb.Reservations.ReservationControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.ReservationController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Exemplars.ReservationFocused
  alias Crit.Servers.Institution
  alias CritBiz.ViewModels.Reservation.CalendarEntry

  setup :logged_in_as_reservation_manager

  setup %{conn: conn} do
    {:ok, conn: put_req_header(conn, "accept", "application/json")}
  end
  
  describe "week_data" do
    test "empty", %{conn: conn} do
      conn = get_via_action(conn, :week_data, "0")
      
      assert json_response(conn, 200)["data"] == []
    end

    test "a reservation", %{conn: conn} do 
      reservation = ReservationFocused.reserved!(@bovine_id,
        ["jeff", "bossie"], ["procedure 1", "proc"],
        date: Institution.today!(@institution))

      assert [result] =
        get_via_action(conn, :week_data, "0")
        |> json_response(200)
        |> Map.get("data")

      # The details of the output are in the CalendarEntry tests.
      assert result["body"] == CalendarEntry.to_map(reservation, @institution).body
    end

    test "a reservation in an earlier week", %{conn: conn} do 
      reservation = ReservationFocused.reserved!(@bovine_id,
        ["jeff", "bossie"], ["procedure 1", "proc"],
        date: Date.add(Institution.today!(@institution), -7))

      assert [result] =
        get_via_action(conn, :week_data, "-1")
        |> json_response(200)
        |> Map.get("data")

      # The details of the output are in the CalendarEntry tests.
      assert result["body"] == CalendarEntry.to_map(reservation, @institution).body
    end
    
  end
end
