defmodule Crit.Types do

  defmacro __using__(_) do
    quote do
      # I'm going to insist that params be honest-to-God params like those
      # that comes from Plug, whereas attrs always have atom keys.
      # This may be excessive tidiness.
      
      @type params() :: %{required(String.t) => String.t | params()}
      @type attrs() :: %{required(:atom) => any()}
      @type db_id() :: integer()
      @type short_name() :: String.t   # usually named `institution`.


      @type nary_error :: {:ok, any()} | {:error, :atom, any()}
    end
  end
end
