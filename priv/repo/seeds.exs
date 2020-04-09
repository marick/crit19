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

alias Crit.Users.PasswordApi
alias Crit.Users.Schemas.User
alias Crit.Users.Schemas.PermissionList
alias Crit.Sql
alias Crit.Setup.HiddenSchemas.Species
alias Crit.Setup.{AnimalApi}
alias Crit.Setup.Schemas.{ServiceGap,Procedure}
alias Crit.Setup.HiddenSchemas.ProcedureFrequency
alias Crit.Global.Constants
alias Crit.Global.SeedConstants
alias Ecto.Datespan

Application.ensure_all_started(:crit)

short_name = Constants.default_institution.short_name


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
}, short_name

:ok = PasswordApi.set_password("marick",
  %{"new_password" => "weepy-communal",
    "new_password_confirmation" => "weepy-communal"},
  short_name)

# This is needless wankery to make sure that ids used in tests
# actually correspond to what's in the database.

bovine_id = SeedConstants.bovine_id
equine_id = SeedConstants.equine_id
unlimited_frequency_id = SeedConstants.unlimited_frequency_id

%{id: ^unlimited_frequency_id} =
  Sql.insert!(%ProcedureFrequency{
        name: "unlimited",
        calculation_name: "unlimited",
        description: "This procedure can be performed many times per day."},
    short_name)

%{id: ^bovine_id} = 
  Sql.insert!(%Species{name: SeedConstants.bovine}, short_name)
%{id: ^equine_id} =
  Sql.insert!(%Species{name: SeedConstants.equine}, short_name)


{:ok, [hank]} = AnimalApi.create_animals(%{"names" => "Hank",
                                    "species_id" => equine_id,
                                    "in_service_datestring" => "2019-10-01",
                                    "out_of_service_datestring" => "never",
                                    "institution" => short_name
                                    }, short_name)
Sql.insert!(%ServiceGap{
      animal_id: hank.id,
      span: Datespan.customary(~D[2023-01-01], ~D[2023-03-03]),
      reason: "seed"}, short_name)



{:ok, _} = Procedure.insert(%{
      name: "Acupuncture demonstration",
      species_id: equine_id,
      frequency_id: unlimited_frequency_id},
  short_name)
{:ok, _} = Procedure.insert(%{
      name: "Caudal epidural",
      species_id: bovine_id,
      frequency_id: unlimited_frequency_id},
  short_name)
{:ok, _} = Procedure.insert(%{
      name: "Hoof exam and care",
      species_id: equine_id,
      frequency_id: unlimited_frequency_id},
  short_name)
{:ok, _} = Procedure.insert(%{
      name: "Hoof exam and care",
      species_id: bovine_id,
      frequency_id: unlimited_frequency_id},
  short_name)
