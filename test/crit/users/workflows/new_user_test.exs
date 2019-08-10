defmodule Crit.Users.Workflow.NewUserTest do
  use Crit.DataCase

  alias Crit.Users
  alias Crit.Examples.PasswordFocused
  alias Crit.Repo
  alias Crit.Users.PasswordToken2

  def creation_and_first_save(params) do
    assert {:ok, %{user: user, token: token}} = Users.create_unactivated_user2(params, @default_institution)
    
    # Just a spot check; unit tests have more
    assert params["email"] == user.email
    assert params["permission_list"]["manage_animals"] == user.permission_list.manage_animals
    assert Repo.get_by(PasswordToken2, text: token.text)
    {user, token}
  end

  def present_password_token(token_text) do
    assert {:ok, _} = Users.user_from_token2(token_text)
  end

  def supply_new_password(user_id, new_password) do
    params = PasswordFocused.params(new_password, new_password)
    assert :ok = Users.set_password(user_id, params, @default_institution)
  end

  test "successful creation through activation" do
    {user, token} = creation_and_first_save(Factory.string_params_for(:user))

    present_password_token(token.text)

    new_password = "something horse something something"
    assert :error = Users.check_password(user.auth_id, new_password, @default_institution)
    supply_new_password(user.auth_id, new_password)
    assert {:ok, user.id} == Users.check_password(user.auth_id, new_password, @default_institution)
  end
end
