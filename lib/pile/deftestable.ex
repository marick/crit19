defmodule Pile.Deftestable do

  @doc """
  Used to mark that a `def` function is a utility for function
  for the containing module, so it should only be used in tests. Intermediate
  between `def` and `defp`.
  """

  defmacro deftestable(head, do: body) do
    if Mix.env() == :test do 
      quote do: (def  unquote(head), do: unquote(body))
    else
      quote do: (defp unquote(head), do: unquote(body))
    end
  end
end
