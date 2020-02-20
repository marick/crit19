defmodule Crit.Setup.InstitutionApi do
  alias Crit.Repo
  alias Crit.Setup.Schemas.{Institution,Timeslot}
  import Crit.Setup.InstitutionServer, only: [server: 1]
  import Ecto.Query
  alias Ecto.Timespan

  def all do
    Repo.all(from Institution)
    |> Enum.map(&put_timeslots/1)
  end

  def one!(kws) do
    Repo.one(from Institution, where: ^kws)
    |> put_timeslots
  end

  def timezone(institution) do
    institution = GenServer.call(server(institution), :raw)
    institution.timezone
  end

  # This could just be a list of names, but the names are arbitrary
  # strings, and I worry about things like smart quotes not making
  # the round trip correctly.
  def timeslot_tuples(institution) do
    GenServer.call(server(institution), :timeslot_tuples)
  end

  def timeslot_name(id, institution) do
    timeslot = timeslot_by_id(id, institution)
    timeslot.name
  end

  def timespan(%Date{} = date, timeslot_id, institution) do
    timeslot = timeslot_by_id(timeslot_id, institution)
    Timespan.from_date_time_and_duration(date, timeslot.start, timeslot.duration)
  end

  def available_species(institution) do
    GenServer.call(server(institution), :available_species)
  end

  def species_name(species_id, institution) do
    available_species(institution)
    |> Enum.find(fn {_, id} -> id == species_id end)
    |> elem(0)
  end

  def timeslots(institution) do 
    GenServer.call(server(institution), :timeslots)
  end

  def timeslot_by_id(id, institution) do 
    {:ok, timeslot} =
      GenServer.call(server(institution), {:timeslot_by_id, id})
    timeslot
  end

  defp put_timeslots(full_institution) do
    %{full_institution |
      timeslots: Repo.all(Timeslot, prefix: full_institution.prefix)}
  end

end
