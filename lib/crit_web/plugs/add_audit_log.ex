defmodule CritWeb.Plugs.AddAuditLog do
  alias CritWeb.Plugs.ConnAudit

  def init(opts), do: opts

  def call(conn, _opts) do
    if ConnAudit.audit_assigned?(conn) do
      conn
    else
      server_module = Crit.Audit.ToEcto.Server
      process_name = server_module
      ConnAudit.assign_audit(conn, server_module, process_name)
    end
  end
end
