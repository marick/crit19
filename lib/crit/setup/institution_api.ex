defmodule Crit.Setup.InstitutionApi do
  alias Crit.Repo
  alias Crit.Setup.Schemas.{Institution,TimeSlot}
  import Crit.Setup.InstitutionServer, only: [server: 1]
  alias Crit.Setup.HiddenSchemas
  alias Crit.Sql

  def all do
    Repo.all(Institution)
  end

  def timezone(institution) do
    institution = GenServer.call(server(institution), :raw)
    institution.timezone
  end

  def available_species(institution) do
    HiddenSchemas.Species.Query.ordered()
    |> Sql.all(institution)
    |> Enum.map(fn %HiddenSchemas.Species{name: name, id: id} -> {name, id} end)
  end
  

  @doc """
  This institution must be in the database(s) for all environments: dev, prod, test. 
  It is also "default" in the sense that a dropdown list of institutions should
  show/select this one by default.
  """
  def default do
    %Institution{
      display_name: "Critter4Us Demo",
      short_name: "critter4us",
      prefix: "demo",
      timezone: "America/Los_Angeles",

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
  end
end
