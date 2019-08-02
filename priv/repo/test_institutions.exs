alias Crit.Repo
alias Crit.Institutions.{Institution}

{:ok, _} = Repo.insert %Institution{
  display_name: "Critter4Us Demo",
  short_name: "critter4us",
  prefix: "demo"
}, prefix: "clients"

