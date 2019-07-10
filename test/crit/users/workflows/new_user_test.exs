defmodule Crit.Users.Workflow.NewUserTest do
  use Crit.DataCase

  alias Crit.Users
  import Crit.Test.Util

  def creation_and_first_save(params) do
    assert {:ok, user} = Users.user_needing_activation(params)
    
    # Just a spot check; unit tests have more
    assert params["email"] == user.email
    assert params["permission_list"]["manage_animals"] == user.permission_list.manage_animals
    assert is_binary(user.password_token.text)

    user
  end

  def present_password_token(user) do
    assert {:ok, _} = Users.user_from_token(user.password_token.text)
  end

  def supply_new_password(user_id, new_password) do
    params = %{"new_password" => new_password,
               "new_password_confirmation" => new_password}
    assert :ok = Users.set_password(user_id, params)
  end

  test "successful creation through activation" do
    user = creation_and_first_save(user_creation_params())

    present_password_token(user)

    new_password = "something horse something something"
    assert :error = Users.check_password(user.auth_id, new_password)
    supply_new_password(user.auth_id, new_password)
    assert :ok = Users.check_password(user.auth_id, new_password)
  end
end
