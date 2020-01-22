alias Crit.Sql
alias Crit.Setup.HiddenSchemas.Species
alias Crit.Global.Constants
alias Crit.Global.Default
alias Crit.Setup.InstitutionApi

Application.ensure_all_started(:crit)

institution = InstitutionApi.default.short_name

# This is needless wankery to make sure that ids used in tests
# actually correspond to what's in the database.

bovine_id = Constants.bovine_id
equine_id = Constants.equine_id

%{id: ^bovine_id} = 
  Sql.insert!(%Species{name: Constants.bovine}, institution)
%{id: ^equine_id} =
  Sql.insert!(%Species{name: Constants.equine}, institution)
