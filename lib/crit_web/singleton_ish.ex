defmodule CritWeb.SingletonIsh do
  @moduledoc """
  These functions are accessors (getters, setters, testers) for information
  that is semi-global in the following sense:
  1. there will be a single value during a production or dev run.
  2. there will be multiple values during the running of async tests,
     though the tests will be unaware of that.

  The ugly name indicates this is a dubious idea, needs a better name, etc.
  """

  import Plug.Conn

  def user_id(conn), do: get_session(conn, :user_id)
  def put_user_id(conn, user_id), do: put_session(conn, :user_id, user_id)
  
  def current_user(conn), do: conn.assigns.current_user
  def has_user?(conn), do: Map.get(conn.assigns, :current_user)
  def put_current_user(conn, user), do: assign(conn, :current_user, user)
  def delete_current_user(conn), do: assign(conn, :current_user, nil)
  
  def institution(_conn), do: "critter4us"
  def put_institution(conn, institution),
    do: put_session(conn, :institution, institution)

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
  def put_token(conn, token), do: put_session(conn, :token, token)
end
