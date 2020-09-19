defmodule Crit.Params.BuildWorkflow do
  alias Crit.Params.Build
  
  def build_step(keywords) do
    start = Enum.into(keywords, %{})

    expanded_exemplars =
      Enum.reduce(start.exemplars, %{}, &Build.add_real_exemplar/2)

    Map.put(start, :exemplars, expanded_exemplars)
    
  end

  defmacro __using__(_) do
    quote do
      use Crit.Errors
      use Crit.TestConstants
      use FlowAssertions.Define
      import Crit.Params.Build, only: [to_strings: 1, like: 2]
      alias Crit.Params.{Get,Validate}
      use FlowAssertions
      use FlowAssertions.Ecto
      import Crit.Params.BuildWorkflow

      # ----------------------------------------------------------------------------

    end
  end  
end
