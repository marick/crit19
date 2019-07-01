defmodule Crit.Accounts do
  import Ecto.Query, warn: false
  alias Crit.Repo

  alias Crit.Accounts.User
  alias Crit.Accounts.PasswordToken

  def list_users do
    Repo.all(User)
  end

  def get_user!(id), do: Repo.get!(User, id)

  def create_user(attrs \\ %{}) do
    User.create_changeset(attrs)
    |> Repo.insert()
  end

  def update_user(%User{} = user, attrs) do
    user
    |> User.update_changeset(attrs)
    |> Repo.update()
  end

  def authenticate_user(auth_id, password) do
    User.authenticate_user(auth_id, password)
  end

  def changeset(%User{} = user) do
    User.edit_changeset(user)
  end

  def create_password_token(%User{} = user) do
    token = Crit.Puid.generate()
    {:ok, result} = 
      %PasswordToken{user_id: user.id, token: token}
      |> Repo.insert
    result.token
  end

  def user_from_unexpired_token(token),
    do: PasswordToken.user_from_unexpired_token(token)
end
