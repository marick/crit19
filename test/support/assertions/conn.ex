defmodule CritWeb.Assertions.Conn do
  use Phoenix.ConnTest
  use Crit.Global.Default
  import CritWeb.ConnExtras
  import ExUnit.Assertions
  import Crit.Assertions.Defchain
  alias CritWeb.PublicController
  alias Crit.Users.User
  import CritWeb.Plugs.Accessors

  ### Redirection

  defchain assert_redirected_to(conn, path),
    do: assert redirected_to(conn) == path

  defchain assert_redirected_home(conn),
    do: assert_redirected_to(conn, PublicController.path(:index))

  defchain assert_redirected_to_authorization_failure_path(conn),
    do: assert redirected_to(conn) == PublicController.path(:index)

  defchain assert_failed_authorization(conn) do
    assert_redirected_to_authorization_failure_path(conn)
    assert flash_error(conn) =~ "not authorized"
  end

  defchain assert_authorization_failures(conn, actions) do
    Enum.map(actions, fn action ->
      assert_failed_authorization(action.(conn))
    end)
  end

  
  ### Session

  defchain assert_logged_in(conn, %User{} = user, institution) do
    assert_logged_in(conn, user.id, institution)
  end

  defchain assert_logged_in(conn, user_id, institution) do
    assert user_id(conn) == user_id
    assert institution(conn) == institution
  end

  defchain refute_logged_in(conn) do
    refute user_id(conn)
    refute institution(conn)
  end

  defchain assert_no_token_in_session(conn), do: refute token(conn)

  defchain assert_session_token(conn, token_text),
    do: assert token(conn).text == token_text


  ### Rendered HTML

  defchain assert_purpose(conn, purpose) do
    assert(html_response(conn, 200) =~
      ~r/Purpose:[[:space:]]+#{Regex.escape(purpose)}/)
  end

  defchain assert_user_sees(conn, claims) when is_list(claims) do
    for claim <- claims, do: assert_user_sees(conn, claim)
  end

  defchain assert_user_sees(conn, claim) do
    assert(html_response(conn, 200) =~ claim)
  end

  defchain refute_user_sees(conn, claim),
    do: refute(html_response(conn, 200) =~ claim)

  defchain assert_links_to(conn, path) do
    href = "href=\"#{path}\""
    assert_user_sees(conn, href)
  end


  ### Flash

  defchain assert_no_flash(conn),
    do: refute(Plug.Conn.get_session(conn, :phoenix_flash))

  defchain assert_info_flash_has(conn, string_or_regex),
    do: assert flash_info(conn) =~ string_or_regex

  defchain assert_error_flash_has(conn, string_or_regex),
    do: assert flash_error(conn) =~ string_or_regex
end
