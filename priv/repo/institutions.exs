alias Crit.Setup.Schemas.{Institution,Timeslot}
alias Crit.Repo

timeslots = [ %{name: "morning (8-noon)",
                 start: ~T[08:00:00],
                 duration: 4 * 60},
               %{name: "afternoon (1-5)",
                 start: ~T[13:00:00],
                 duration: 4 * 60},
               %{name: "evening (6-midnight)",
                 start: ~T[18:00:00],
                 duration: 5 * 60},
               %{name: "all day (8-5)",
                 start: ~T[08:00:00],
                 duration: 9 * 60},
             ]


{:ok, _} = Repo.insert %Institution{
  display_name: "Critter4Us Demo",
  short_name: "critter4us",
  prefix: "demo",
  timezone: "America/Los_Angeles"
}

Repo.insert_all(Timeslot, timeslots, prefix: "demo")

{:ok, _} = Repo.insert %Institution{
  display_name: "University of Illinois",
  short_name: "illinois",
  prefix: "illinois",
  timezone: "America/Chicago"
}

Repo.insert_all(Timeslot, timeslots, prefix: "illinois")

