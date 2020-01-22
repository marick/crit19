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
alias Crit.Setup.HiddenSchemas.Species
alias Crit.Setup.{AnimalApi,InstitutionApi}
alias Crit.Setup.Schemas.ServiceGap
alias Crit.Global.Constants
alias Ecto.Datespan

Application.ensure_all_started(:crit)

institution = InstitutionApi.default.short_name


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
  %{"new_password" => "weepy-communal",
    "new_password_confirmation" => "weepy-communal"},
  institution)

# This is needless wankery to make sure that ids used in tests
# actually correspond to what's in the database.

bovine_id = Constants.bovine_id
equine_id = Constants.equine_id

%{id: ^bovine_id} = 
  Sql.insert!(%Species{name: Constants.bovine}, institution)
%{id: ^equine_id} =
  Sql.insert!(%Species{name: Constants.equine}, institution)


{:ok, [hank]} = AnimalApi.create_animals(%{"names" => "Hank",
                                    "species_id" => equine_id,
                                    "in_service_datestring" => "today",
                                    "out_of_service_datestring" => "never",
                                    "institution" => institution
                                    }, institution)
Sql.insert!(%ServiceGap{
      animal_id: hank.id,
      span: Datespan.customary(~D[2023-01-01], ~D[2023-03-03]),
      reason: "seed"}, institution)


IO.inspect AnimalApi.updatable!(hank.id, institution)
