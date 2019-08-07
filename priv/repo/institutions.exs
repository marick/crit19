alias Crit.Repo
alias Crit.Institutions.{Institution}
alias Crit.Institutions

{:ok, _} = Repo.insert(Institutions.default_institution, prefix: "clients")

{:ok, _} = Repo.insert %Institution{
  display_name: "University of Illinois",
  short_name: "illinois",
  prefix: "illinois"
}, prefix: "clients"

