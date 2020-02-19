alias Crit.Sql
alias Crit.Setup.HiddenSchemas.Species
alias Crit.Global.Constants

Application.ensure_all_started(:crit)

short_name = Constants.default_institution.short_name
bovine_id = Constants.bovine_id
equine_id = Constants.equine_id

%{id: ^bovine_id} = 
  Sql.insert!(%Species{name: Constants.bovine}, short_name)
%{id: ^equine_id} =
  Sql.insert!(%Species{name: Constants.equine}, short_name)
