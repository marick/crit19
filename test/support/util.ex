defmodule Crit.Test.Util do
  use ExUnit.CaseTemplate
  alias Crit.Factory
  alias Crit.Users.{Password}
  alias Crit.Users

  def password_params(password),
    do: password_params(password, password)
  
  def password_params(password, confirmation) do
    %{"new_password" => password,
      "new_password_confirmation" => confirmation
    }
  end

  def user_with_password(password) do
    user = Factory.insert(:user)
    assert Password.count_for(user.auth_id) == 0
    assert :ok == Users.set_password(user.auth_id, password_params(password, password))
    assert Password.count_for(user.auth_id) == 1
    user
  end
end
