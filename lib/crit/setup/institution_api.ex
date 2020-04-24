defmodule Crit.Setup.InstitutionApi do
  alias Crit.Repo
  alias Crit.Setup.Schemas.Institution
  import Crit.Setup.InstitutionServer, only: [server: 1]
  import Ecto.Query
  alias Ecto.Timespan
  alias Pile.TimeHelper

  def species(institution), do: get(:species, institution)
  def procedure_frequencies(institution), do: get(:procedure_frequencies, institution)
  def timeslots(institution), do: get(:timeslots, institution)

  # ----------------------------------------------------------------------------

  def all do
    Repo.all(from Institution)
  end

  def timezone(institution) do
    get(:institution, institution).timezone
  end

  def today!(institution) do
    timezone = timezone(institution)
    TimeHelper.today_date(timezone)
  end

  def timeslot_name(id, institution) do
    by_id(:timeslots, id, institution).name
  end

  def timespan(%Date{} = date, timeslot_id, institution) do
    timeslot = by_id(:timeslots, timeslot_id, institution)
    Timespan.from_date_time_and_duration(date, timeslot.start, timeslot.duration)
  end

  def species_name(id, institution) do
    by_id(:species, id, institution).name
  end

  def procedure_frequency_name(id, institution) do
    by_id(:procedure_frequencies, id, institution).name
  end

  # ----------------------------------------------------------------------------
  
  defp get(key, institution),
    do: GenServer.call(server(institution), {:get, key})

  defp by_id(key, id, institution),
    do: get(key, institution) |> EnumX.find_by_id(id)
end
