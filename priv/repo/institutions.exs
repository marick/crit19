alias Crit.Setup.Schemas.{Institution,TimeSlot}
alias Crit.Global
alias Crit.Repo

{:ok, _} = Repo.insert(Global.Default.institution)

{:ok, _} = Repo.insert %Institution{
  display_name: "University of Illinois",
  short_name: "illinois",
  prefix: "illinois",
  timezone: "America/Chicago",

  time_slots: [ %TimeSlot{name: "morning (8-noon)",
                          start: ~T[08:00:00],
                          duration: 4 * 60},
                %TimeSlot{name: "afternoon (1-5)",
                          start: ~T[13:00:00],
                          duration: 4 * 60},
                %TimeSlot{name: "evening (6-midnight)",
                          start: ~T[18:00:00],
                          duration: 5 * 60},
                %TimeSlot{name: "all day (8-5)",
                          start: ~T[08:00:00],
                          duration: 9 * 60},
              ]
  
}

