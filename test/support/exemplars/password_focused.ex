defmodule Crit.Exemplars.PasswordFocused do
  use ExUnit.CaseTemplate
  alias Crit.Factory
  alias Crit.Users.{Password}
  alias Crit.Users
  alias Crit.Sql
  use Crit.Institutions.Default

  def params(password),
    do: params(password, password)
  
  def params(password, confirmation) do
    %{"new_password" => password,
      "new_password_confirmation" => confirmation
    }
  end

  def user(password) do
    user = Factory.build(:user) |> Sql.insert!(@default_short_name)
    assert Password.count_for(user.auth_id, @default_short_name) == 0
    assert :ok == Users.set_password(user.auth_id, params(password, password), @default_short_name)
    assert Password.count_for(user.auth_id, @default_short_name) == 1
    user
  end
end
