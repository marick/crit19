alias Crit.Repo
alias Crit.Setup.Schemas.Timeslot
alias Crit.Global.Constants
alias Crit.Global.SeedConstants


{:ok, _} = Repo.insert Constants.default_institution
Repo.insert_all(Timeslot, SeedConstants.default_timeslots,
  prefix: Constants.default_prefix)

