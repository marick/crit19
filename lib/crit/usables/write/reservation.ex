defmodule Crit.Usables.Write.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Sql

  schema "reservations" do
    field :timespan, Timespan
    field :species_id, :id


    field :start_date, :date, virtual: true
    field :start_time, :time, virtual: true
    field :minutes, :integer, virtual: true
    timestamps()
  end

  @required [:start_date, :start_time, :minutes, :species_id]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> populate_timespan
  end

  def create(attrs, institution) do
    %__MODULE__{}
    |> changeset(attrs)
    |> Sql.insert(institution)
  end


  def populate_timespan(%{valid?: false} = changeset), do: changeset
  def populate_timespan(%{changes: changes} = changeset) do
    timespan = Timespan.from_date_time_and_duration(
      changes.start_date, changes.start_time, changes.minutes)
    put_change(changeset, :timespan, timespan)
  end
end
