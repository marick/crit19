defmodule CritWeb.Reservations.BlockingAuthorizationTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.{AfterTheFactController,ReservationController}
  alias Crit.Users.PermissionList

  test "how an unlogged-in user is blocked", %{conn: conn} do
    assert_authorization_failures(conn,
      [&(get &1, AfterTheFactController.path(:start)),
       &(post &1, AfterTheFactController.path(:put_species_and_time)),
       &(post &1, AfterTheFactController.path(:put_procedures)),
       &(post &1, AfterTheFactController.path(:put_animals)),

       &(get &1, ReservationController.path(:show, 1)),
       &(get &1, ReservationController.path(:by_dates_form)),
      ])
  end

  describe "how logged-in user without permissions is blocked" do
    setup %{conn: conn} do
      no_access = %PermissionList{make_reservations: false}
      [conn: logged_in_with_permissions(conn, no_access)]
    end

    test "blocked", %{conn: conn} do
      assert_authorization_failures(conn,
        [&(get &1, AfterTheFactController.path(:start)),
         &(post &1, AfterTheFactController.path(:put_species_and_time)),
         &(post &1, AfterTheFactController.path(:put_procedures)),
         &(post &1, AfterTheFactController.path(:put_animals)),

         &(get &1, ReservationController.path(:show, 1)),
         &(get &1, ReservationController.path(:by_dates_form)),
        ])
    end
  end
end

