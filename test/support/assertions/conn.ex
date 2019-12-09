defmodule CritWeb.Assertions.Conn do
  use Phoenix.ConnTest
  use Crit.Global.Default
  import CritWeb.ConnExtras
  import ExUnit.Assertions
  import Crit.Assertions.Defchain
  alias CritWeb.PublicController

  defchain assert_no_flash(conn),
    do: refute(Plug.Conn.get_session(conn, :phoenix_flash))
  
  defchain assert_user_sees(conn, claims) when is_list(claims) do
    for claim <- claims, do: assert_user_sees(conn, claim)
  end

  defchain assert_user_sees(conn, claim), 
    do: assert(html_response(conn, 200) =~ claim)

  defchain refute_user_sees(conn, claim),
    do: refute(html_response(conn, 200) =~ claim)

  defchain assert_purpose(conn, purpose) do
    assert(html_response(conn, 200) =~
      ~r/Purpose:[[:space:]]+#{Regex.escape(purpose)}/)
  end

  defchain assert_redirected_to_authorization_failure_path(conn),
    do: assert redirected_to(conn) == PublicController.path(:index)

  
  defchain assert_failed_authorization(conn) do
    assert_redirected_to_authorization_failure_path(conn)
    assert flash_error(conn) =~ "not authorized"
  end

  defchain assert_links_to(conn, path) do
    href = "href=\"#{path}\""
    assert_user_sees(conn, href)
  end

  defchain assert_authorization_failures(conn, actions) do
    Enum.map(actions, fn action ->
      assert_failed_authorization(action.(conn))
    end)
  end
end
