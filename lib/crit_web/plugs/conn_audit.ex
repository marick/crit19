defmodule CritWeb.Plugs.ConnAudit do
  use Phoenix.Controller, namespace: CritWeb

  def server(conn), do: conn.assigns.audit_server
  def pid(conn), do: conn.assigns.audit_pid

  def send_struct(conn, struct),
    do: apply(server(conn), :put, [pid(conn), struct])

  def assign_audit(conn, module, name_or_pid) do
    conn
    |> assign(:audit_server, module)
    |> assign(:audit_pid, name_or_pid)
  end

  def audit_assigned?(conn), do: Map.has_key?(conn.assigns, :audit_server)
end

