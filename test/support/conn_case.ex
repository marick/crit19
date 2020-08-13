defmodule CritWeb.ConnCase do
  @moduledoc """
  This module defines the test case to be used by
  tests that require setting up a connection.

  Such tests rely on `Phoenix.ConnTest` and also
  import other functionality to make it easier
  to build common data structures and query the data layer.

  Finally, if the test case interacts with the database,
  it cannot be async. For this reason, every test runs
  inside a transaction which is reset at the beginning
  of the test unless the test case is marked as async.
  """

  use ExUnit.CaseTemplate

  using do
    quote do
      # Import conveniences for testing with connections
      use Phoenix.ConnTest
      alias CritWeb.Router.Helpers, as: Routes
      alias Crit.Factory
      import CritWeb.Templates.Purpose
      alias CritWeb.Controller.Common
      import CritWeb.ConnExtras
      import CritWeb.Assertions.Conn
      alias Crit.Audit.ToMemory.Server, as: AuditServer
      import CritWeb.Plugs.Accessors
      use Crit.TestConstants
      use Crit.Mock
      alias Crit.Extras.SqlT
      import FlowAssertions
      import Crit.Assertions.Form
      use Crit.Errors

      # The default endpoint for testing
      @endpoint CritWeb.Endpoint
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Crit.Repo)

    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Crit.Repo, {:shared, self()})
    end

    audit_module = Crit.Audit.ToMemory.Server
    audit_pid = start_supervised!(audit_module)
    conn =
      Phoenix.ConnTest.build_conn()
      |> Plug.Test.init_test_session([])
      |> CritWeb.Plugs.Accessors.assign_audit(audit_module, audit_pid)

    {:ok, conn: conn}
  end
end
