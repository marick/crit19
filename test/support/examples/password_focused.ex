defmodule Crit.Examples.PasswordFocused do
  use ExUnit.CaseTemplate
  alias Crit.Factory
  alias Crit.Users.{Password}
  alias Crit.Users
  alias Crit.Repo
  alias Crit.Sql
  import CritWeb.SingletonIsh
  

  def params(password),
    do: params(password, password)
  
  def params(password, confirmation) do
    %{"new_password" => password,
      "new_password_confirmation" => confirmation
    }
  end

  def user(password) do
    user = Factory.build(:user) |> Repo.insert!(prefix: "demo")
    assert Password.count_for(user.auth_id) == 0
    assert :ok == Users.set_password(user.auth_id, params(password, password))
    assert Password.count_for(user.auth_id) == 1
    user
  end
end
