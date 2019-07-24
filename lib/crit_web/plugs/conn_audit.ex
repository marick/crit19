defmodule CritWeb.Plugs.ConnAudit do
  def server(conn), do: conn.assigns.audit_server
  def pid(conn), do: conn.assigns.audit_pid

  def send_struct(conn, struct),
    do: apply(server(conn), :put, [pid(conn), struct])
end

