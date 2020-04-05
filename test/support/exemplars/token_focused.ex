defmodule Crit.Exemplars.TokenFocused do
  use ExUnit.CaseTemplate
  use Crit.Global.Constants
  alias Crit.Users.UserApi
  alias Crit.Factory
  import Crit.Assertions.Misc


  def user(attrs \\ []) do
    Factory.string_params_for(:user, attrs)
    |> UserApi.create_unactivated_user(@institution)
    |> ok_payload
  end
end
