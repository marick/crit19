defmodule Crit.Users.PasswordApi do
  import Ecto.Query, warn: false
  alias Crit.Users.{UserHavingToken, UniqueId}
  alias Crit.Users.Schemas.{PasswordToken, Password}
  alias Crit.Sql
  alias Crit.Repo

  def fresh_password_changeset(), do: Password.default_changeset()
      
  def set_password(auth_id, params, institution) do
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

  def attempt_login(auth_id, proposed_password, institution) do
    password =
      Password.Query.by_auth_id(auth_id)
      |> Password.Query.preloading_user
      |> Sql.one(institution)
    
    if password && Pbkdf2.verify_pass(proposed_password, password.hash) do
      {:ok, UniqueId.new(password.user.id, institution)}
    else
      Pbkdf2.no_user_verify()
      :error
    end
  end
  
end
