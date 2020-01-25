defmodule Crit.Setup.InstitutionApi do
  alias Crit.Repo
  alias Crit.Setup.Schemas.{Institution,TimeSlot}
  import Crit.Setup.InstitutionServer, only: [server: 1]
  import Ecto.Query
  alias Ecto.Timespan

  def all do
    Repo.all(from Institution, preload: :time_slots)
  end

  def one!(kws) do
    Repo.one(from Institution, where: ^kws, preload: :time_slots)
  end

  def timezone(institution) do
    institution = GenServer.call(server(institution), :raw)
    institution.timezone
  end

  # This could just be a list of names, but the names are arbitrary
  # strings, and I worry about things like smart quotes not making
  # the round trip correctly.
  def time_slot_tuples(institution) do
    GenServer.call(server(institution), :time_slots)
  end

  def time_slot_name(id, institution) do
    time_slot = time_slot_by_id(id, institution)
    time_slot.name
  end

  def timespan(%Date{} = date, time_slot_id, institution) do
    time_slot = time_slot_by_id(time_slot_id, institution)
    time_tuple = Time.to_erl(time_slot.start)
    date_tuple = Date.to_erl(date)
    datetime = NaiveDateTime.from_erl!({date_tuple, time_tuple})
    Timespan.plus(datetime, time_slot.duration, :minute)
  end

  def available_species(institution) do
    GenServer.call(server(institution), :available_species)
  end

  def species_name(species_id, institution) do
    available_species(institution)
    |> Enum.find(fn {_, id} -> id == species_id end)
    |> elem(0)
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

  

  defp time_slot_by_id(id, institution) do 
    {:ok, time_slot} =
      GenServer.call(server(institution), {:time_slot_by_id, id})
    time_slot
  end

end
