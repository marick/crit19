defmodule CritWeb.DataAccessors do 
  use Phoenix.Controller, namespace: CritWeb

  # User information
  
  def user_id(conn), do: Plug.Conn.get_session(conn, :user_id)

  def current_user(conn), do: conn.assigns.current_user

  def has_user?(conn), do: Map.get(conn.assigns, :current_user)



  # Audit information

  def audit_server(conn), do: conn.assigns.audit_server
  def audit_pid(conn), do: conn.assigns.audit_pid

  def assign_audit(conn, module, name_or_pid) do
    conn
    |> assign(:audit_server, module)
    |> assign(:audit_pid, name_or_pid)
  end

  def audit_assigned?(conn), do: Map.has_key?(conn.assigns, :audit_server)
end
