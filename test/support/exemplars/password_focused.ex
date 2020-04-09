defmodule Crit.Exemplars.PasswordFocused do
  use ExUnit.CaseTemplate
  alias Crit.Users.Schemas.Password
  alias Crit.Users.PasswordApi
  use Crit.TestConstants
  alias Crit.Exemplars.Minimal

  def params(password),
    do: params(password, password)
  
  def params(password, confirmation) do
    %{"new_password" => password,
      "new_password_confirmation" => confirmation
    }
  end

  def user(password) do
    user = Minimal.user()
    assert :ok == PasswordApi.set_password(user.auth_id, params(password, password), @institution)
    assert Password.count_for(user.auth_id, @institution) == 1
    user
  end
end
