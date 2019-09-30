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

alias Crit.Users
alias Crit.Users.{User,PermissionList}
alias Crit.Sql
alias Crit.Usables.Write.Species
alias Crit.Global.Constants
alias Crit.Global.Default

Application.ensure_all_started(:crit)

institution = Default.institution.short_name


{:ok, _} = Sql.insert %User{
  display_name: "Brian Marick",
  auth_id: "marick",
  email: "marick@exampler.com",
  permission_list: %PermissionList{
    manage_and_create_users: true,
    manage_animals: true,
    make_reservations: true,
    view_reservations: true,
  }
}, institution

:ok = Users.set_password("marick",
  %{"new_password" => "merchant-province-weepy-communal",
    "new_password_confirmation" => "merchant-province-weepy-communal"},
  institution)

# This is needless wankery to make sure that ids used in tests
# actually correspond to what's in the database.

bovine_id = Constants.bovine_id
equine_id = Constants.equine_id

%{id: ^bovine_id} = 
  Sql.insert!(%Species{name: Constants.bovine}, institution)
%{id: ^equine_id} =
  Sql.insert!(%Species{name: Constants.equine}, institution)
