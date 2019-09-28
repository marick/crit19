defmodule CritWeb.UserManagement.BlockingAuthorizationTest do
  use CritWeb.ConnCase
  alias CritWeb.UserManagement.UserController

  def assert_auth_failure(conn, action) do
    action.(conn)
    |> assert_failed_authorization
  end

  def assert_auth_failures(conn, actions) do
    Enum.map(actions, fn action -> assert_auth_failure(conn, action) end)
  end

  describe "how unlogged-in user is blocked" do
    test "An attempt to reach the UserController without a login redirects",
    %{conn: conn} do

    assert_auth_failures(conn,
      [&(get &1, UserController.path(:new)), 
       &(get &1, UserController.path(:index)),
       &(get &1, UserController.path(:show, 1)),
       &(get &1, UserController.path(:edit, 1)),

       &(post &1, UserController.path(:create, params: %{})),
       &(post &1, UserController.path(:create, id: 1, params: %{})),
      ])
    end
  end


  describe "how logged-in user without permissions is blocked" do

    setup :setup_logged_in

    test "blocked",
    %{conn: conn} do

    assert_auth_failures(conn,
      [&(get &1, UserController.path(:new)), 
       &(get &1, UserController.path(:index)),
       &(get &1, UserController.path(:show, 1)),
       &(get &1, UserController.path(:edit, 1)),

       &(post &1, UserController.path(:create, params: %{})),
       &(post &1, UserController.path(:create, id: 1, params: %{})),
      ])
    end
  end
end

