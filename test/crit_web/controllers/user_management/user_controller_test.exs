defmodule CritWeb.UserManagement.UserControllerTest do
  use CritWeb.ConnCase, async: true
  alias CritWeb.UserManagement.UserController, as: UnderTest
  use CritWeb.ConnShorthand, controller: UnderTest
  alias Crit.Users

  setup %{conn: conn} do
    conn = logged_in_as_user_manager(conn)
    [conn: conn]
  end


  describe "index" do
    test "boilerplate", %{conn: conn} do
      conn = get_via_action [conn, :index]
      assert_purpose conn, list_active_users()
      assert_links_to conn, UnderTest.path([conn, :new])
    end

    test "lists all users", %{conn: conn} do
      # Note that the user manager isn't stored in the database
      user = Factory.insert(:user)
      conn = get_via_action [conn, :index]
      assert_user_sees(conn, [user.auth_id, user.display_name, user.email])
    end
  end

  

  describe "new user" do
    test "renders form", %{conn: conn} do
      conn = get_via_action [conn, :new]
      assert_purpose conn, form_for_creating_new_user()
    end
  end

  describe "create user" do
    setup do
      [act: fn conn, params -> post_to_action([conn, :create], :user, params) end]
    end
    
    test "redirects to provide another new-user form when data is valid",
      %{conn: conn, act: act} do
      conn = act.(conn, Factory.string_params_for(:user))
      assert ready_for_new_user?(conn)
    end

    test "renders errors when data is invalid",
      %{conn: conn, act: act} do
      conn = act.(conn, Factory.string_params_for(:user, display_name: ""))
      assert_retry_same_user(conn)
      assert_user_sees(conn, standard_blank_error())
    end


    test "blanks are trimmed",
      %{conn: conn, act: act} do

      odd_user = Factory.string_params_for(:user,
        display_name: "     lots of blanks       ",
        auth_id: "   blank filled      ",
        email: "     test@exampler.com      "
      )
      conn = act.(conn, odd_user)
      assert ready_for_new_user?(conn)

      assert {:ok, user} = Users.user_from_auth_id("blank filled")
      assert "lots of blanks" == user.display_name
      assert "test@exampler.com" == user.email
    end

    test "an audit record is created", %{conn: conn, act: act} do
      params = Factory.string_params_for(:user)
      act.(conn, params)

      assert {:ok, audit} = Crit.Audit.ToMemory.Server.latest(conn.assigns.audit_pid)

      assert audit.event == "created user"
      assert audit.event_owner_id == conn.assigns.current_user.id
      assert audit.data.auth_id == params["auth_id"]
    end
  end


  def ready_for_new_user?(conn),
    do: redirected_to(conn) == UnderTest.path [conn, :new]

  def assert_retry_same_user(conn), 
    do: assert_purpose conn, form_for_creating_new_user()


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
