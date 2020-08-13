defmodule Crit.Exemplars.TokenFocused do
  use ExUnit.CaseTemplate
  use Crit.TestConstants
  alias Crit.Users.UserApi
  alias Crit.Factory
  use FlowAssertions


  def user(attrs \\ []) do
    Factory.string_params_for(:user, attrs)
    |> UserApi.create_unactivated_user(@institution)
    |> ok_content
  end
end
