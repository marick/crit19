defmodule CritWeb.Plugs.FetchUserTest do
  use CritWeb.ConnCase, async: true
  alias CritWeb.Plugs.FetchUser
  import Crit.DataExtras
  import Crit.PlugExtras
  alias Crit.Repo

  setup %{conn: conn}, do: plug_setup(conn)

  def logged_in_with_irrelevant_permissions(conn) do
    user = Factory.build(:user)
    assert_without_permissions(user)
    logged_in(conn, user)
  end
    
  test "works fine if there's nothing in the session", %{conn: conn} do
    refute get_session(conn, :user_id)
    conn = FetchUser.call(conn, [])
    refute conn.halted
    refute conn.assigns.current_user
  end

  test "obeys a pre-set :current_user (for testing)", %{conn: conn} do
    user = Factory.build(:user)
    conn =
      conn
      |> assign(:current_user, user)
      |> FetchUser.call([])
    refute conn.halted
    assert current_user(conn) == user
  end

  test "user id doesn't exist in database (should be impossible)", %{conn: conn} do
    conn =
      conn
      |> put_session(:user_id, 7573333)
      |> FetchUser.call([])
    refute conn.halted   # It doesn't count as an error.
    refute current_user(conn)
  end

  test "fetch user from database", %{conn: conn} do
    user = Factory.build(:user) |> Repo.insert!(prefix: "demo")
    conn =
      conn
      |> put_session(:user_id, user.id)
      |> FetchUser.call([])
    refute conn.halted
    assert current_user(conn).id == user.id
  end

end
