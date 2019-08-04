defmodule Crit.Users do
  import Ecto.Query, warn: false
  alias Crit.Repo
  import Ecto.Changeset
  import Crit.OkError

  alias Crit.Users.User
  alias Crit.Users.PasswordToken
  alias Crit.Users.Password
  alias Crit.Users.PermissionList
  alias Crit.Sql

  @default_institution "critter4us"

  # Primarily about users

  def fresh_user_changeset() do
    User.default_changeset(%User{permission_list: %PermissionList{}})
    # I used to think you needed an embedded changeset (within the
    # `data` field of the changeset so as to prevent the changeset
    # being marked dirty, but apparently not. If it turns out I was
    # right before, here's the alternate code. 
    #    embedded_changeset = PermissionList.changeset(%PermissionList{})
    #    User.default_changeset(%User{permission_list: embedded_changeset})
  end

  def user_from_auth_id(auth_id, institution \\ @default_institution) do
    User
    |> Sql.get_by([auth_id: auth_id], institution)
    |> lift_nullable("no such user '#{auth_id}'")
  end

  def permissioned_user_from_id(id, institution \\ @default_institution) do    
    id |> User.Query.permissioned_user |> Sql.one(institution)
  end

  def active_users(institution \\ @default_institution) do
    User.Query.active_users |> Sql.all(institution)
  end
  

  # Primarily about passwords

  def fresh_password_changeset(), do: Password.default_changeset()
      
  def set_password(auth_id, params, institution \\ @default_institution) do
    conflict_behavior = [on_conflict: :replace_all, conflict_target: :auth_id]
    
    result =
      %Password{auth_id: auth_id}
      |> Password.create_changeset(params)
      |> Sql.insert(conflict_behavior, institution)
    case result do
      {:ok, _} -> :ok  # Results should never be of interest
      error -> error
    end
  end

  def check_password(auth_id, proposed_password, institution \\ @default_institution) do
    password =
      Password.Query.by_auth_id(auth_id)
      |> Password.Query.preloading_user
      |> Sql.one(institution)
    
    if password && Pbkdf2.verify_pass(proposed_password, password.hash) do
      {:ok, password.user.id}
    else
      Pbkdf2.no_user_verify()
      :error
    end
  end

  # Primarily about tokens

  def user_needing_activation(params, institution \\ @default_institution) do
    User.create_changeset(params)
    |> put_change(:password_token, PasswordToken.unused())
    |> Sql.insert(institution)
  end

  def user_from_token(token_text, institution \\ @default_institution) do
    PasswordToken.Query.expired_tokens |> Repo.delete_all(prefix: "demo")

    user =
      token_text 
      |> PasswordToken.Query.matching_user
      |> preload(:password_token)
      |> Sql.one(institution)

    if user,
      do: PasswordToken.force_update(user.password_token, NaiveDateTime.utc_now)
    
    lift_nullable(user, "missing token '#{token_text}'")
  end


  def user_has_password_token?(user_id, institution \\ @default_institution),
    do: user_id |> PasswordToken.Query.by_user_id |> Repo.exists?(prefix: "demo")

  def delete_password_token(user_id, institution \\ @default_institution) do
    user_id |> PasswordToken.Query.by_user_id |> Repo.delete_all(prefix: "demo")
    # There is no need for deletion information to leak out
    :ok
  end

end
