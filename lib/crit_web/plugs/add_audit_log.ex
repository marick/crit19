defmodule CritWeb.Plugs.AddAuditLog do
  import Plug.Conn

  def init(opts), do: opts

  def call(conn, _opts) do
    if conn.assigns[:audit_server] do
      conn
    else
      conn
      |> assign(:audit_server, Crit.Audit.ToEcto.Server)
      |> assign(:audit_pid, Crit.Audit.ToEcto.Server)
    end
  end
end
