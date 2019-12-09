defmodule CritWeb.ConnExtras do
  use ExUnit.CaseTemplate
  use Phoenix.ConnTest
  alias Crit.Factory
  alias Crit.Sql
  import CritWeb.Plugs.Accessors
  use Crit.Global.Default
  alias Phoenix.HTML
  alias Crit.Audit.ToMemory.Server, as: Audit


  # CONN GETTERS

  def flash_error(conn),
    do: Plug.Conn.get_session(conn, :phoenix_flash)["error"]

  def flash_info(conn),
    do: Plug.Conn.get_session(conn, :phoenix_flash)["info"]

  def standard_blank_error, do: "can&#39;t be blank"

  def latest_audit_record(conn), do: Audit.latest(audit_pid(conn))

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
