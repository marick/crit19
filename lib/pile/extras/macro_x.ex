defmodule Pile.Extras.MacroX do

  def inspect_macro(env, ast) do
    Macro.expand_once(ast, env) |> Macro.to_string |> IO.inspect
  end
end
