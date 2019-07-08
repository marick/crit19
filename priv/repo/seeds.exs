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
alias Crit.Users.User

Repo.insert %User{
  display_name: "Brian Marick",
  auth_id: "marick",
  email: "marick@exampler.com",
}

  
IO.inspect %Crit.Users.PermissionList{}
