defmodule CritWeb.ConnShorthand do
  use Phoenix.ConnTest
  import ExUnit.Assertions

  defmacro __using__(controller: controller) do
    quote do
      
      defp get_via_action(args) do 
        conn = hd(args)
        get(conn, unquote(controller).path(args))
      end

      defp post_to_action(path_args, payload_key, payload_params) do
        conn = hd(path_args)
        post(conn, unquote(controller).path(path_args),
          %{payload_key => payload_params})
      end

      defp delete_via_action(path_args) do
        conn = hd(path_args)
        delete(conn, unquote(controller).path(path_args))
      end

      defp assert_will_post_to(conn, action) do
        assert html_response(conn, 200) =~ "method=\"post\""
        post_to = unquote(controller).path([conn, action])
        assert html_response(conn, 200) =~ "action=\"#{post_to}\""
      end
    end
  end
end
