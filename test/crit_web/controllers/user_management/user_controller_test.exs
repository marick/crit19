defmodule CritWeb.UserManagement.UserControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.UserManagement.UserController, as: Own
  use Crit.Test.Controller, controller: Own

  # describe "index" do
  #   test "lists all users", %{conn: conn} do
  #     conn = get(conn, Routes.user_management_user_path(conn, :index))
  #     assert html_response(conn, 200) =~ "Listing Users"
  #   end
  # end

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get_via_action [conn, :new]
      assert_rendered conn, "new.html"
    end
  end

  describe "create user" do
    setup do
      [act: fn conn, params -> post_to_action([conn, :create], user: params) end]
    end
    
    test "redirects to provide another new-user form when data is valid",
      %{conn: conn, act: act} do
      conn = act.(conn, user_creation_params())
      assert redirected_to(conn) == Own.path [conn, :new]
    end

    test "renders errors when data is invalid",
      %{conn: conn, act: act} do
      conn = act.(conn, user_creation_params(display_name: ""))
      assert_rendered conn, "new.html"
      assert html_response(conn, 200) =~ standard_blank_error()
    end
  end


  # describe "edit user" do
  #   setup [:create_user]

  #   test "renders form for editing chosen user", %{conn: conn, user: user} do
  #     conn = get(conn, Routes.user_management_user_path(conn, :edit, user))
  #     assert html_response(conn, 200) =~ "Edit User"
  #   end
  # end

  # describe "update user" do
  #   setup [:create_user]

  #   test "redirects when data is valid", %{conn: conn, user: user} do
  #     conn = put(conn, Routes.user_management_user_path(conn, :update, user), user: @update_attrs)
  #     assert redirected_to(conn) == Routes.user_management_user_path(conn, :show, user)

  #     conn = get(conn, Routes.user_management_user_path(conn, :show, user))
  #     assert html_response(conn, 200)
  #   end

  #   test "renders errors when data is invalid", %{conn: conn, user: user} do
  #     conn = put(conn, Routes.user_management_user_path(conn, :update, user), user: @invalid_attrs)
  #     assert html_response(conn, 200) =~ "Edit User"
  #   end
  # end



end
