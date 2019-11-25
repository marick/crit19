defmodule Crit.Assertions.Defchain do

  defmacro defchain(head, do: body) do
    quote do
      def unquote(head) do
        _called_for_side_effect = unquote(body)
        unquote(value_arg(head))
      end
    end
  end

  defp value_arg(head) do
    case head do
      {:when, _env, [true_head | _]} ->
        value_arg(true_head)
      _ -> 
        {_name, _, args} = head
        [value_arg | _] = args
        value_arg
    end
  end
end
