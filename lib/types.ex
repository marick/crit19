defmodule Crit.Types do

  defmacro __using__(_) do
    quote do 
      @type params() :: %{required(String.t) => String.t | params()}
    end
  end
end
