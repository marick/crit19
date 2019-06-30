defmodule Crit.Accounts.PasswordToken do
  use Ecto.Schema
  import Ecto.Changeset
  import Crit.Accounts.User

  schema "password_tokens" do
    field :token, :string
    field :user_id, :id

    timestamps()
  end
end
