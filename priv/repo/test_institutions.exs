alias Crit.Repo
alias Crit.Setup.Schemas.Timeslot
alias Crit.Global.Constants


{:ok, _} = Repo.insert Constants.default_institution
Repo.insert_all(Timeslot, Constants.default_timeslots,
  prefix: Constants.default_prefix)

