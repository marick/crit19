defmodule CritWeb.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      use CritWeb.ConnCase
      use PhoenixIntegration
    end
  end

end
