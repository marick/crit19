defmodule CritWeb.Controller.Path do
  alias CritWeb.Router.Helpers, as: Routes
  alias CritWeb.Endpoint
  
  defmacro __using__(function_atom) do
    quote do
      def path(action),
        do: apply(Routes, unquote(function_atom), [Endpoint, action])
      def path(action, param),
        do: apply(Routes, unquote(function_atom), [Endpoint, action, param])
   end
  end
end
