defmodule Crit.Users.Workflow.NewUserTest do
  use Crit.DataCase

  alias Crit.Users
  alias Crit.Exemplars.{PasswordFocused}
  alias Crit.Users.{UserHavingToken, Password}
  alias Crit.Sql

  def creation_and_first_save(params) do
    {:ok, %UserHavingToken{user: user, token: token}}
       = Users.create_unactivated_user(params, @default_short_name)
    {user, token}
  end

  def present_password_token(token_text) do
    assert {:ok, _} = Users.one_token(token_text)
  end

  def user_has_no_password(auth_id) do
    refute Sql.exists?(Password, [auth_id: auth_id], @default_short_name)
  end

  def supply_new_password(user_id, new_password) do
    params = PasswordFocused.params(new_password, new_password)
    assert :ok = Users.set_password(user_id, params, @default_short_name)
  end

  def user_has_valid_password(auth_id, password) do
    assert {:ok, _} =
      Users.check_password(auth_id, password, @default_short_name)
  end

  test "successful creation through activation" do
    admin_uses_params = Factory.string_params_for(:user)
    {user, token} = creation_and_first_save(admin_uses_params)

    present_password_token(token.text)
    user_has_no_password(user.auth_id)

    new_password = "something horse something something"
    supply_new_password(user.auth_id, new_password)
    user_has_valid_password(user.auth_id, new_password)
  end
end
