defmodule Pile.Aspect do

  @moduledoc """
  Name is a vague gesture toward aspect-oriented programming. These
  functions introduce explicit "join points" in the code.

  All join points are the same, but names like `spy_on` make intention
  more clear. (If you're familiar with the jargon.)
  """

  import Mockery.Macro

  def spy_on(x), do: mockable(x)
  def some(x), do: mockable(x)
end
