defmodule Crit.Params.OneToManyBuilder do
  @moduledoc """
  A builder for controller params of this form:

  %{
    "names" => "a, b, c"
    "more" => ...,
    ...
  }

  The result of processing is the creation of N rows.
  """

  defmacro __using__(_) do 
    quote do
      use Crit.Params.Builder
      alias Crit.Params.Builder
      alias Crit.Params.Validation
      
      defp make_params_for_name(config, name), do: Builder.only(config(), name)

      def that_are(descriptor), do: Builder.only(config(), descriptor)

    end
  end  
end
