defmodule Crit.Users.UserApi do
  import Ecto.Query, warn: false
  alias Crit.Users.UserHavingToken
  alias Crit.Users.Schemas.{User, PasswordToken}
  alias Crit.Users.UserImpl.Read
  alias Crit.Sql
  alias Crit.Repo

  def fresh_user_changeset(), do: User.fresh_user_changeset()

  def permissioned_user_from_id(id, institution),
    do: Read.permissioned_user_from_id(id, institution)

  def active_users(institution), do: Read.active_users(institution)

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
end
