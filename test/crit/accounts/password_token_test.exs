defmodule Crit.Accounts.PasswordTokenTestg do
  use Crit.DataCase

  alias Crit.Accounts
  alias Ecto.Changeset
  alias Crit.Accounts.PasswordToken

  setup do
    user = saved_user()
    token = Accounts.create_password_token(user)

    [user: user, token: token]
  end
  
  test "creation", %{user: user, token: token} do
    assert String.length(token) > 10

    assert {:ok, id} = Accounts.id_from_unexpired_tokens(token)
    assert id == user.id

    assert :error = Accounts.id_from_unexpired_tokens("bogus")
  end

  test "reads are destructive", %{token: token} do
    assert {:ok, _} = Accounts.id_from_unexpired_tokens(token)
    assert :error = Accounts.id_from_unexpired_tokens(token)
  end

  test "reads expire after a time", %{token: token} do
    row = Repo.get_by(PasswordToken, token: token)
    barely_valid = PasswordToken.expiration_threshold(row.inserted_at)
    expired = NaiveDateTime.add(barely_valid, -1)
    Changeset.change(row, inserted_at: expired) |> Repo.update

    assert :error = Accounts.id_from_unexpired_tokens(token)
  end
end
