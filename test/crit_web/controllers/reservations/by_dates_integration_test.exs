defmodule CritWeb.Reservations.ByAnimalIntegrationTest do
  use CritWeb.IntegrationCase
  alias CritWeb.Reservations.ReservationController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  # alias Crit.Servers.UserTask
  # alias Crit.Exemplars.Available
  # alias Crit.Reservations.ReservationApi
  # alias Crit.Setup.InstitutionApi
  # alias Ecto.Timespan
  alias Crit.Exemplars.ReservationFocused

  setup :logged_in_as_reservation_manager

  setup do
    ReservationFocused.reserved!(@bovine_id,
      ["Jeff", "bossie"], ["procedure 1", "procedure 2"],
      date: @date_1)
    :ok
  end


  test "by-dates workflow", %{conn: conn} do 
    # ----------------------------------------------------------------------------
    get_via_action(conn, :by_dates_form)
    |> assert_purpose(reservation_by_dates())
    # ----------------------------------------------------------------------------
    |> follow_form(%{date_or_dates:
                    %{first_datestring: @iso_date_1,
                      last_datestring: "just one day"}})
    |> assert_purpose(reservation_by_dates())
    |> assert_user_sees("Jeff")
    |> assert_user_sees("bossie")
  end
end
