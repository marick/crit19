alias Crit.Sql
alias Crit.Usables.Species

Application.ensure_all_started(:crit)

Sql.insert!(%Species{name: "bovine"}, "critter4us")
Sql.insert!(%Species{name: "equine"}, "critter4us")
