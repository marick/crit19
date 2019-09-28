alias Crit.Global.{Institution}
alias Crit.Global
alias Crit.Repo

{:ok, _} = Repo.insert(Global.Default.institution)

{:ok, _} = Repo.insert %Institution{
  display_name: "University of Illinois",
  short_name: "illinois",
  prefix: "illinois",
  timezone: "America/Chicago"
}

