defmodule Crit.Mock do
  import Mockery

  defmacro given(modulename, args, do: body) do
    {{:., _, [module, fn_name]},
      _, _
    } = modulename

    fn_descriptor = [{fn_name, length(args)}]

    quote do
      mock(unquote(module), unquote(fn_descriptor), fn(unquote_splicing(args)) ->
        unquote(body)
      end)
    end
  end

  defmacro __using__(_) do
    quote do
      require Crit.Mock
      import Crit.Mock

      # These are frequent metaconstants: that is, values about which 
      # nothing is known but their identity and type.
      @id_M "id__"
      @params_M %{"params__" => "values__"}
    end
  end
end
