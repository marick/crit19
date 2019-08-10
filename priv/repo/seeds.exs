# Script for populating the database. You can run it as:
#
#     mix run priv/repo/seeds.exs
#
# Inside the script, you can read and write to any of your
# repositories directly:
#
#     Crit.Repo.insert!(%Crit.SomeSchema{})
#
# We recommend using the bang functions (`insert!`, `update!`
# and so on) as they will fail if something goes wrong.

alias Crit.Repo
alias Crit.Users.{User,PermissionList}

{:ok, _} = Repo.insert %User{
  display_name: "Brian Marick",
  auth_id: "marick",
  email: "marick@exampler.com",
  permission_list: %PermissionList{
    manage_and_create_users: true,
    manage_animals: true,
    make_reservations: true,
    view_reservations: true,
  }
}, prefix: "demo"

# :ok = Users.set_password("marick",
#   %{"new_password" => "merchant-province-weepy-communal",
#     "new_password_confirmation" => "merchant-province-weepy-communal"})
