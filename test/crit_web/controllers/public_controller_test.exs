defmodule CritWeb.PublicControllerTest do
  use CritWeb.ConnCase

  test "GET /", %{conn: conn} do
    assert conn = get(conn, "/")
  end
end
