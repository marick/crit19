defmodule Crit.Accounts.PasswordTokenTest do
  use Crit.DataCase

  alias Crit.Accounts
  alias Ecto.Changeset
  alias Crit.Accounts.PasswordToken
  alias Crit.Repo

  setup do
    user = saved_user()
    token = Accounts.create_password_token(user)

    [user: user, token: token]
  end
  
  test "creation", %{token: token} do
    assert String.length(token) > 10

    assert {:ok, user} = Accounts.user_from_unexpired_token(token)

    assert :error = Accounts.user_from_unexpired_token("bogus")
  end

  test "reads are destructive", %{token: token} do
    assert {:ok, user} = Accounts.user_from_unexpired_token(token)
    assert :error = Accounts.user_from_unexpired_token(token)
  end

  test "reads expire after a time", %{token: token} do
    row = Repo.get_by(PasswordToken, token: token)
    barely_valid = PasswordToken.expiration_threshold(row.inserted_at)
    expired = NaiveDateTime.add(barely_valid, -1)
    Changeset.change(row, inserted_at: expired) |> Repo.update

    assert :error = Accounts.user_from_unexpired_token(token)
  end
end
