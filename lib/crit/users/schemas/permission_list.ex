defmodule Crit.Users.Schemas.PermissionList do
  use Ecto.Schema
  import Ecto.Changeset

  schema "permission_lists" do
    belongs_to :user, Crit.Users.User
    field :manage_and_create_users, :boolean, default: false
    field :manage_animals, :boolean, default: false
    field :make_reservations, :boolean, default: false
    field :view_reservations, :boolean, default: true

    timestamps()
  end

  @fields [:manage_and_create_users, :manage_animals, :make_reservations,
           :view_reservations]


  def changeset(permission_list, params \\ %{}) do
    permission_list
    |> cast(params, @fields)
    |> validate_required(@fields)
  end
end
