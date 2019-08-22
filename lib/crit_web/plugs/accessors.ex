defmodule CritWeb.Plugs.Accessors do
  @moduledoc """
  These functions are accessors (getters, setters, testers) for information
  that is stored in `Plug.Conn` and is semi-global in the following sense:
  1. there will be a single value during a production or dev run.
  2. there will be multiple values during the running of async tests,
     though the tests will be unaware of that.
  """

  import Plug.Conn
  alias Crit.Users.UniqueId

  def put_unique_id(conn, user_id, institution) do
    unique_id = %UniqueId{user_id: user_id, institution: institution}
    put_session(conn, :unique_id, unique_id)
  end


  def unique_id(conn), do: get_session(conn, :unique_id)

  def user_id(conn), do: unique_id(conn) && unique_id(conn).user_id
  def institution(conn), do: unique_id(conn) && unique_id(conn).institution
  
  def current_user(conn), do: conn.assigns.current_user
  def has_user?(conn), do: Map.get(conn.assigns, :current_user)
  def put_current_user(conn, user), do: assign(conn, :current_user, user)
  def delete_current_user(conn), do: assign(conn, :current_user, nil)
  
  # Audit information

  def audit_server(conn), do: conn.assigns.audit_server
  def audit_pid(conn), do: conn.assigns.audit_pid

  def assign_audit(conn, module, name_or_pid) do
    conn
    |> assign(:audit_server, module)
    |> assign(:audit_pid, name_or_pid)
  end

  def audit_assigned?(conn), do: Map.has_key?(conn.assigns, :audit_server)

  # Etc.
  
  def token(conn), do: get_session(conn, :token)
  def remember_token(conn, token), do: put_session(conn, :token, token)
  def forget_token(conn), do: delete_session(conn, :token)
end
