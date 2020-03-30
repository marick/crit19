defmodule CritWeb.UserManagement.BlockingAuthorizationTest do
  use CritWeb.ConnCase
  alias CritWeb.UserManagement.UserController
  alias Crit.Users.Schemas.PermissionList
  
  test "how an unlogged-in user is blocked", %{conn: conn} do

    assert_authorization_failures(conn,
      [&(get &1, UserController.path(:new)), 
       &(get &1, UserController.path(:index)),
       &(get &1, UserController.path(:show, 1)),
       &(get &1, UserController.path(:edit, 1)),

       &(post &1, UserController.path(:create, params: %{})),
       &(post &1, UserController.path(:create, id: 1, params: %{})),
      ])
  end


  describe "how logged-in user without needed permissions is blocked" do

    setup %{conn: conn} do
      no_access = %PermissionList{manage_and_create_users: false}
      [conn: logged_in_with_permissions(conn, no_access)]
    end


    test "blocked", %{conn: conn} do

    assert_authorization_failures(conn,
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

