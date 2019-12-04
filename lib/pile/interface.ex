defmodule Pile.Interface do
  import Mockery.Macro

  def some(x), do: mockable(x)
end
