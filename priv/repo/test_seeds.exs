alias Crit.Sql
alias Crit.Setup.Schemas.{Species,ProcedureFrequency}
alias Crit.Global.Constants
alias Crit.Global.SeedConstants

Application.ensure_all_started(:crit)

short_name = Constants.default_institution.short_name
bovine_id = SeedConstants.bovine_id
equine_id = SeedConstants.equine_id
unlimited_frequency_id = SeedConstants.unlimited_frequency_id
once_per_week_frequency_id = SeedConstants.once_per_week_frequency_id

%{id: ^bovine_id} = 
  Sql.insert!(%Species{name: SeedConstants.bovine}, short_name)
%{id: ^equine_id} =
  Sql.insert!(%Species{name: SeedConstants.equine}, short_name)

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
        description: "Describe once-per-week"},
    short_name)

