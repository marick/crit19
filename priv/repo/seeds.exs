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
# alias Crit.Accounts
# alias Crit.Accounts.User

# This lets me repopulate the database without deleting the tables,
# which is a pain because I've always got Postico open to the database.
# Repo.delete_all(User)


# {:ok, _} = Accounts.create_user %{
#   name: "Brian Marick",
#   email: "marick@exampler.com",
#   password: "password",
# }
