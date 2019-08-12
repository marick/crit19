defmodule Crit.Exemplars.PasswordFocused do
  use ExUnit.CaseTemplate
  alias Crit.Factory
  alias Crit.Users.{Password}
  alias Crit.Users
  alias Crit.Sql
  alias Crit.Exemplars.MinimalUser

  @default_institution "critter4us"

  def params(password),
    do: params(password, password)
  
  def params(password, confirmation) do
    %{"new_password" => password,
      "new_password_confirmation" => confirmation
    }
  end

  def user(password, opts) do
    user = MinimalUser.user(opts)
    assert Password.count_for(user.auth_id, @default_institution) == 0
    assert :ok == Users.set_password(user.auth_id, params(password, password), @default_institution)
    assert Password.count_for(user.auth_id, @default_institution) == 1
    user
  end
end
