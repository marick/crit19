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
alias Crit.Setup.AnimalApi
alias Crit.Setup.Schemas.{ServiceGap,Procedure,Species,ProcedureFrequency}
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
once_per_day_frequency_id = SeedConstants.once_per_day_frequency_id
once_per_week_frequency_id = SeedConstants.once_per_week_frequency_id
twice_per_week_frequency_id = SeedConstants.twice_per_week_frequency_id

%{id: ^unlimited_frequency_id} =
  Sql.insert!(%ProcedureFrequency{
        name: "unlimited",
        calculation_name: "unlimited",
        description: "This procedure can be performed many times per day."},
    short_name)
%{id: ^once_per_week_frequency_id} =
  Sql.insert!(%ProcedureFrequency{
        name: "once per week",
        calculation_name: "once per week",
        description:
        """
        The procedure can be performed at most once per week. For example,
        if an animal has been used on Friday, the earliest it can be
        used again is on the next Friday.
        """},
    short_name)
%{id: ^once_per_day_frequency_id} =
  Sql.insert!(%ProcedureFrequency{
        name: "once per day",
        calculation_name: "once per day",
        description:
        """
        The procedure can be performed at most one time per day. It is OK to
        perform the procedure late at night and then first thing in the morning
        of the next day. 
        """},
    short_name)

%{id: ^twice_per_week_frequency_id} =
  Sql.insert!(%ProcedureFrequency{
        name: "twice per week",
        calculation_name: "twice per week",
        description:
        """
        The procedure can be performed at most twice per week. There must be
        at least one full day between uses. (That is, using the same
        animal every Tuesday and Thursday is fine, but Tuesday and Wednesday is
        not allowed.
        """},
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
      frequency_id: once_per_week_frequency_id},
  short_name)
{:ok, _} = Procedure.insert(%{
      name: "Caudal epidural",
      species_id: bovine_id,
      frequency_id: once_per_week_frequency_id},
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
