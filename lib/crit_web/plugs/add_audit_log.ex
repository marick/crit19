defmodule CritWeb.Plugs.AddAuditLog do
  import CritWeb.DataAccessors

  def init(opts), do: opts

  def call(conn, _opts) do
    if audit_assigned?(conn) do  # Allow tests to override standard audit log.
      conn
    else
      server_module = Crit.Audit.ToEcto.Server
      process_name = server_module
      assign_audit(conn, server_module, process_name)
    end
  end
end
