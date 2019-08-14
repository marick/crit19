alias Crit.Institutions.{Institution}
alias Crit.Institutions
alias Crit.Repo

{:ok, _} = Repo.insert(Institutions.Default.institution)

{:ok, _} = Repo.insert %Institution{
  display_name: "University of Illinois",
  short_name: "illinois",
  prefix: "illinois"
}

