defmodule CritWeb.CurrentUser.SessionControllerTest do
  use CritWeb.ConnCase
  alias CritWeb.CurrentUser.SessionController, as: UnderTest
  use CritWeb.ConnMacros, controller: UnderTest
  alias Crit.Examples.PasswordFocused
  alias CritWeb.PublicController
  alias Crit.Institutions
  alias Crit.Institutions.{Institution}

  setup %{conn: conn} do
    [conn: Plug.Test.init_test_session(conn, [])]
  end
  
  describe "handling login fields" do
    test "first time has empty fields", %{conn: conn} do
      conn = get_via_action(conn, :get_login_form)
      assert_will_post_to(conn, :try_login)
      assert_purpose conn, show_login_form()
      assert_no_flash(conn)
    end

    test "login failure leaves auth id visible but zeroes password field",
      %{conn: conn} do
      auth_id = "bogus auth id"
      password = "this is a bogus password"
      conn = post_to_action(conn, :try_login,
        under(:login, auth_id: auth_id, password: password, institution: @default_institution))

      assert_purpose conn, show_login_form()
      assert_user_sees(conn, [Common.form_error_message, auth_id])
      refute_user_sees(conn, password)
      refute get_session(conn, :user_id)
    end

    test "successful login", %{conn: conn} do
      password = "password"
      user = PasswordFocused.user(password)
      refute get_session(conn, :user_id)

      conn = post_to_action(conn, :try_login,
        under(:login, auth_id: user.auth_id, password: password, institution: @default_institution))
      assert redirected_to(conn) == PublicController.path(:index)
      assert get_session(conn, :user_id) == user.id
    end
  end

  describe "logout" do
    test "you can't log out if you're already logged out", %{conn: conn} do
      conn = delete_via_action(conn, :logout)
      assert redirected_to(conn) == Routes.public_path(conn, :index)
      assert get_flash(conn, :error) =~ "You must be logged in"
    end


    test "logout clears session", %{conn: conn} do
      conn = logged_in(conn)
      conn = delete_via_action(conn, :logout)

      assert redirected_to(conn) == Routes.public_path(conn, :index)
      refute get_session(conn, :user_id)
    end
  end

  @irrelevant "irrelevant"

  describe "turning a list of institutions into a simpler structure" do
    setup do
      [default: Institutions.default_institution]
    end

    test "`selected` argument is just returned", %{default: default} do
      assert {_, "passed in"} =
        UnderTest.institution_options("passed in", [default])
    end
    
    test "just the default institution", %{default: default} do 
      assert {list, _} =
        UnderTest.institution_options(@irrelevant, [default])
      assert list == [{default.display_name, default.short_name}]
    end

    test "default comes first", %{default: default} do
      originally_first = %Institution{display_name: "AA", short_name: "aacup"}

      assert {[one, two], _} =
        UnderTest.institution_options(@irrelevant, [originally_first, default])
      
      assert one == {default.display_name, default.short_name}
      assert two == {originally_first.display_name, originally_first.short_name}
    end      

    test "results are sorted by display name", %{default: default} do
      # Note that the short_names are in opposite orders of the display names.
      zzz = %Institution{display_name: "zzz", short_name: "aa"}
      aaa = %Institution{display_name: "aaa", short_name: "zz"}

      assert {[one, two, three], _} =
        UnderTest.institution_options(@irrelevant, [zzz, default, aaa])
      
      assert one == {default.display_name, default.short_name}
      assert two == {aaa.display_name, aaa.short_name}
      assert three == {zzz.display_name, zzz.short_name}
    end      

  end
  
end
