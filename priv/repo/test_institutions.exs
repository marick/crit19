alias Crit.Clients
alias Crit.Institutions.{Institution}
alias Crit.Institutions

{:ok, _} = Clients.insert(Institutions.default_institution)

