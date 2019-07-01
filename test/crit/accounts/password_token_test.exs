defmodule Crit.Accounts.PasswordTokenTest do
  use Crit.DataCase

  alias Crit.Accounts
  alias Ecto.Changeset
  alias Crit.Accounts.PasswordToken
  alias Crit.Repo

  setup do
    user = saved_user(password_token: %{text: PasswordToken.suitable_text()})
    [user: user, token: user.password_token]
  end
  
  test "reads are destructive", %{user: original, token: token} do
    assert {:ok, fetched_user} = Accounts.user_from_unexpired_token(token.text)
    assert_close_enough(original, fetched_user)
    assert :error = Accounts.user_from_unexpired_token(token.text)
  end

  test "reads expire after a time", %{token: token} do
    barely_valid = PasswordToken.expiration_threshold(token.inserted_at)
    expired = NaiveDateTime.add(barely_valid, -1)
    Changeset.change(token, inserted_at: expired) |> Repo.update

    assert :error = Accounts.user_from_unexpired_token(token.text)
  end
end
