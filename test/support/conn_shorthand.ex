defmodule CritWeb.ConnShorthand do
  use Phoenix.ConnTest
  import ExUnit.Assertions

  defmacro __using__(controller: controller) do
    quote do
      
      defp get_via_action__new(conn, action) do 
        get(conn, unquote(controller).path__new(action))
      end

      defp get_via_action__new(conn, action, param) do 
        get(conn, unquote(controller).path__new(action, param))
      end

      defp post_to_action__new(conn, action, payload) do
        post(conn, unquote(controller).path__new(action), payload)
      end

      defp under(payload_key, params),
        do: %{payload_key => params}

      defp delete_via_action__new(conn, action) do
        delete(conn, unquote(controller).path__new(action))
      end

      defp assert_will_post_to(conn, action) do
        assert html_response(conn, 200) =~ "method=\"post\""
        post_to = unquote(controller).path__new(action)
        assert html_response(conn, 200) =~ "action=\"#{post_to}\""
      end
    end
  end
end
