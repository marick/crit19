defmodule CritWeb.ConnExtras do
  use Phoenix.ConnTest
  import ExUnit.Assertions
  alias Crit.Factory
  alias CritWeb.PublicController
  alias Crit.Sql
  import CritWeb.Plugs.Accessors
  use Crit.Institutions.Default

  # ASSERTIONS

  def assert_no_flash(conn),
    do: refute Plug.Conn.get_session(conn, :phoenix_flash)

  def assert_user_sees(conn, claims) when is_list(claims), 
    do: for claim <- claims, do: assert_user_sees(conn, claim)

  def assert_user_sees(conn, claim),
    do: assert html_response(conn, 200) =~ claim

  def refute_user_sees(conn, claim),
    do: refute html_response(conn, 200) =~ claim

  def assert_purpose(conn, purpose),
    do: assert html_response(conn, 200) =~
      ~r/Purpose:[[:space:]]+#{Regex.escape(purpose)}/

  def assert_redirected_to_authorization_failure_path(conn),
    do: assert redirected_to(conn) == PublicController.path(:index)
  
  def assert_failed_authorization(conn) do
    assert_redirected_to_authorization_failure_path(conn)
    assert flash_error(conn) =~ "not authorized"
  end

  def assert_links_to(conn, path) do
    href = "href=\"#{path}\""
    assert_user_sees(conn, href)
  end


  # CONN GETTERS

  def flash_error(conn),
    do: Plug.Conn.get_session(conn, :phoenix_flash)["error"]

  def flash_info(conn),
    do: Plug.Conn.get_session(conn, :phoenix_flash)["info"]

  def standard_blank_error, do: "can&#39;t be blank"

  # USERS

  def logged_in_with_permissions(conn, permissions) do
    manager = Factory.build(:user, permission_list: permissions) |> Sql.insert!(@default_short_name)
    logged_in(conn, manager)
  end

  def logged_in(conn, user \\ Factory.insert(:user)) do
    conn
    |> assign(:current_user, user)
    |> put_unique_id(user.id, @default_short_name)
  end
    

  # For use with `setup`
  def logged_in_as_user_manager(%{conn: conn}) do
    permissions = Factory.build(:permission_list, manage_and_create_users: true)

    [conn: logged_in_with_permissions(conn, permissions)]
  end

end
