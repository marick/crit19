defmodule Crit.Users.UserImpl.Read do
  alias Crit.Sql
  
  defmodule Query do
    import Ecto.Query
    alias Crit.Users.Schemas.User

    def permissioned_user(id) do
      from u in User,
        where: u.id == ^id,
        preload: :permission_list
    end

    def active_users() do
      from u in User,
        where: u.active == true
    end
  end

  # ------------------------------------------------------------------------

  def permissioned_user_from_id(id, institution),
    do: id |> Query.permissioned_user |> Sql.one(institution)

  def active_users(institution),
    do: Query.active_users |> Sql.all(institution)
end
  
