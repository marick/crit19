defmodule Crit.Users do
  import Ecto.Query, warn: false
  alias Crit.Repo
  import Ecto.Changeset
  import Crit.OkError

  alias Crit.Users.User
  alias Crit.Users.PasswordToken
  alias Crit.Users.Password

  # Primarily about users

  def user_from_auth_id(auth_id) do
    User
    |> Repo.get_by(auth_id: auth_id)
    |> lift_nullable("no such user '#{auth_id}'")
  end

  # Primarily about passwords

  def fresh_password_changeset(), do: Password.default_changeset()
      
  def set_password(auth_id, params) do
    result =
      %Password{auth_id: auth_id}
      |> Password.changeset(params)
      |> Repo.insert(on_conflict: :replace_all, conflict_target: :auth_id)
    case result do
      {:ok, _} -> :ok  # Results should never be of interest
      error -> error
    end
  end

  def check_password(auth_id, proposed_password) do
    password = Repo.get_by(Password, auth_id: auth_id)
    if password && Pbkdf2.verify_pass(proposed_password, password.hash) do
      :ok
    else
      Pbkdf2.no_user_verify()
      :error
    end
  end

  # Primarily about tokens

  def user_needing_activation(params) do
    User.create_changeset(params)
    |> put_change(:password_token, PasswordToken.unused())
    |> Repo.insert()
  end

  def user_from_token(token_text) do
    PasswordToken.Query.expired_tokens |> Repo.delete_all

    user =
      token_text 
      |> PasswordToken.Query.matching_user
      |> preload(:password_token)
      |> Repo.one

    if user,
      do: PasswordToken.force_update(user.password_token, NaiveDateTime.utc_now)
    
    lift_nullable(user, "missing token '#{token_text}'")
  end


  def user_has_password_token?(user_id),
    do: user_id |> PasswordToken.Query.by_user_id |> Repo.exists?

  def delete_password_token(user_id) do
    user_id |> PasswordToken.Query.by_user_id |> Repo.delete_all
    # There is no need for deletion information to leak out
    :ok
  end

end
