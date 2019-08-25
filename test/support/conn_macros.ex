defmodule CritWeb.ConnMacros do
  use Phoenix.ConnTest
  import ExUnit.Assertions

  defmacro __using__(controller: controller) do
    quote do
      
      defp get_via_action(conn, action) do 
        get(conn, unquote(controller).path(action))
      end

      defp get_via_action(conn, action, param) do 
        get(conn, unquote(controller).path(action, param))
      end

      defp post_to_action(conn, action, payload) do
        post(conn, unquote(controller).path(action), payload)
      end

      defp delete_via_action(conn, action) do
        delete(conn, unquote(controller).path(action))
      end

      defp assert_will_post_to(conn, action) do
        assert html_response(conn, 200) =~ "method=\"post\""
        post_to = unquote(controller).path(action)
        assert html_response(conn, 200) =~ "action=\"#{post_to}\""
      end
    end
  end
end
