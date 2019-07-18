defmodule Crit.PlugExtras do

  # It would seem natural to have this be done within a `use PlugCase`,
  # akin to the `ConnCase` `setup` block, but that produces errors:
  #
  #       ** (Plug.Conn.AlreadySentError) the response was already sent

  def plug_setup(conn) do
    conn =
      conn
      |> Plug.Test.init_test_session([])
      |> Phoenix.ConnTest.bypass_through(CritWeb.Router, :browser)
      |> Phoenix.ConnTest.dispatch(CritWeb.Endpoint, :get, "/")
    [conn: conn]
  end
end
