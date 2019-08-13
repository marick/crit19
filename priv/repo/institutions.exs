alias Crit.Clients
alias Crit.Institutions.{Institution}
alias Crit.Institutions

{:ok, _} = Clients.insert(Institutions.Default.institution)

{:ok, _} = Clients.insert %Institution{
  display_name: "University of Illinois",
  short_name: "illinois",
  prefix: "illinois"
}

