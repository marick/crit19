defmodule CritWeb.Reservations.BlockingAuthorizationTest do
  use CritWeb.ConnCase
  alias CritWeb.Reservations.ReservationController
  alias Crit.Users.PermissionList

  test "how an unlogged-in user is blocked", %{conn: conn} do
    assert_authorization_failures(conn,
      [&(get &1, ReservationController.path(:backdated_form)),
      ])
  end

  describe "how logged-in user without permissions is blocked" do
    setup %{conn: conn} do
      no_access = %PermissionList{make_reservations: false}
      [conn: logged_in_with_permissions(conn, no_access)]
    end

    test "blocked", %{conn: conn} do
      assert_authorization_failures(conn,
        [&(get &1, ReservationController.path(:backdated_form)),
        ])
    end
  end
end

