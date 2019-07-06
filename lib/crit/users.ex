defmodule Crit.Users do
  import Ecto.Query, warn: false
  alias Crit.Repo
  import Ecto.Changeset

  alias Crit.Users.User
  alias Crit.Users.PasswordToken
  alias Crit.Users.Password


  def user_needing_activation(params) do
    User.create_changeset(params)
    |> put_change(:password_token, PasswordToken.unused())
    |> Repo.insert()
  end

  def user_id_from_token(token_text) do
    case Repo.get_by(PasswordToken, text: token_text) do
      %PasswordToken{user_id: user_id} ->
        {:ok, user_id}
    end
  end
      
  def set_password(user_id, params) do
    result =
      %Password{user_id: user_id}
      |> Password.changeset(params)
      |> Repo.insert(on_conflict: :replace_all, conflict_target: :user_id)
    case result do
      {:ok, _} -> :ok
    end
  end

  def hash_for_auth_id(auth_id) do
    query =
      from u in User,
      where: u.auth_id == ^auth_id,
      join: p in Password, on: p.user_id == u.id,
      select: [p.hash]
    case Repo.one(query) do
      [hash] -> hash
      nil -> nil
    end
  end

  def check_password(auth_id, proposed_password) do
    hash = hash_for_auth_id(auth_id)
    if hash && Pbkdf2.verify_pass(proposed_password, hash) do
      :ok
    else
      Pbkdf2.no_user_verify()
      :error
    end
  end
  
end
