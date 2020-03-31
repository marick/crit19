defmodule Crit.Users.UserApi do
  import Ecto.Query, warn: false
  import Crit.OkError

  alias Crit.Users.{UserHavingToken, UniqueId}
  alias Crit.Users.Schemas.{User, PasswordToken}
  alias Crit.Users.UserImpl.Read
  alias Crit.Sql
  alias Crit.Repo
  import Crit.Users.PasswordApi

  # Primarily about users

  def fresh_user_changeset(), do: User.fresh_user_changeset()

  def permissioned_user_from_id(id, institution),
    do: Read.permissioned_user_from_id(id, institution)

  def active_users(institution), do: Read.active_users(institution)


  # Primarily about tokens


  # Note: this could be made transactional using Ecto.Multi, but
  # that would break for the first institution that had its own
  # database.
  def create_unactivated_user(params, institution) do
    with(
      {:ok, user} <- User.creation_changeset(params) |> Sql.insert(institution),
      token <- Repo.insert!(PasswordToken.new(user.id, institution))
    ) do
      {:ok, UserHavingToken.new(user, token)}
    end
  end

  def one_token(token_text) do
    PasswordToken.Query.expired_tokens |> Repo.delete_all()
    case Repo.get_by(PasswordToken, text: token_text) do
      nil ->
        lift_nullable(nil, "missing token '#{token_text}'")
      token ->
        PasswordToken.force_update(token, NaiveDateTime.utc_now)
        {:ok, token}
    end
  end

  def redeem_password_token(
    %PasswordToken{user_id: user_id,
                   institution_short_name: institution,
                   text: text},
    password_params) do 
    # Note: a transaction isn't useful here because the assumption that
    # users are never deleted (just inactivated) is pervasive in this code,
    # so the `get` "cannot" fail. 
    user = Sql.get(User, user_id, institution)
    retval = set_password(user.auth_id, password_params, institution)
    case retval do
      :ok ->
        delete_password_token(text)
        {:ok, UniqueId.new(user_id, institution)}
      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def delete_password_token(token_text) do
    PasswordToken.Query.by(text: token_text) |> Repo.delete_all
    # There is no need for deletion information to leak out
    :ok
  end

end
