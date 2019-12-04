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
      @id__ "any old id"
      @id_list__ ["one id", "another"]
      @params__ %{"params__" => "values__"}
      @animal__ "any old animal"
      @animal_list__ ["any old animal", "and another"]
    end
  end
end
