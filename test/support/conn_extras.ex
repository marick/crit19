defmodule CritWeb.ConnExtras do
  use ExUnit.CaseTemplate
  use Phoenix.ConnTest
  import ExUnit.Assertions
  alias Crit.Factory
  alias CritWeb.PublicController
  alias Crit.Sql
  import CritWeb.Plugs.Accessors
  use Crit.Global.Default
  alias Phoenix.HTML

  # ASSERTIONS

  def assert_no_flash(conn) do 
    refute(Plug.Conn.get_session(conn, :phoenix_flash))
    conn
  end

  def assert_user_sees(conn, claims) when is_list(claims) do 
    for claim <- claims, do: assert_user_sees(conn, claim)
    conn
  end

  def assert_user_sees(conn, claim) do 
    assert(html_response(conn, 200) =~ claim)
    conn
  end

  def refute_user_sees(conn, claim)  do 
    refute(html_response(conn, 200) =~ claim)
    conn
  end

  def assert_purpose(conn, purpose) do 
    assert(html_response(conn, 200) =~
      ~r/Purpose:[[:space:]]+#{Regex.escape(purpose)}/)
    conn
  end

  def assert_redirected_to_authorization_failure_path(conn) do 
    assert redirected_to(conn) == PublicController.path(:index)
    conn
  end
  
  def assert_failed_authorization(conn) do
    assert_redirected_to_authorization_failure_path(conn)
    assert flash_error(conn) =~ "not authorized"
    conn
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
    manager = Factory.build(:user, permission_list: permissions) |> Sql.insert!(@institution)
    logged_in(conn, manager)
  end

  def logged_in(conn, user \\ Factory.insert(:user)) do
    conn
    |> assign(:current_user, user)
    |> put_unique_id(user.id, @institution)
  end
    

  # For use with `setup`
  def setup_logged_in(%{conn: conn}, opts \\ []) do
    permissions = Factory.build(:permission_list, opts)
    [conn: logged_in_with_permissions(conn, permissions)]
  end
  
  def logged_in_as_user_manager(context),
    do: setup_logged_in(context, manage_and_create_users: true)
  def logged_in_as_usables_manager(context),
    do: setup_logged_in(context, manage_animals: true)

  def under(payload_key, params), do: %{payload_key => params}


  # Etc

  @doc """
  Takes a plain string and converts it to a string with HTML entities inserted
  as rendering would. Most importantly, it replaces an apostrophe with `&#39;`. 
  """
  def html_version(string),
    do: string |> HTML.html_escape |> HTML.safe_to_string
  
end
