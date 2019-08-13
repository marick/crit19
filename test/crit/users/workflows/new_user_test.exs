defmodule Crit.Users.Workflow.NewUserTest do
  use Crit.DataCase

  alias Crit.Users
  alias Crit.Exemplars.PasswordFocused
  alias Crit.Repo
  alias Crit.Users.PasswordToken

  def creation_and_first_save(params) do
    assert {:ok, %{user: user, token: token}} = Users.create_unactivated_user(params, @default_short_name)
    
    # Just a spot check; unit tests have more
    assert params["email"] == user.email
    assert params["permission_list"]["manage_animals"] == user.permission_list.manage_animals
    assert Repo.get_by(PasswordToken, text: token.text)
    {user, token}
  end

  def present_password_token(token_text) do
    assert {:ok, _} = Users.one_token(token_text)
  end

  def supply_new_password(user_id, new_password) do
    params = PasswordFocused.params(new_password, new_password)
    assert :ok = Users.set_password(user_id, params, @default_short_name)
  end

  test "successful creation through activation" do
    {user, token} = creation_and_first_save(Factory.string_params_for(:user))

    present_password_token(token.text)

    new_password = "something horse something something"
    assert :error = Users.check_password(user.auth_id, new_password, @default_short_name)
    supply_new_password(user.auth_id, new_password)
    assert {:ok, user.id} == Users.check_password(user.auth_id, new_password, @default_short_name)
  end
end
