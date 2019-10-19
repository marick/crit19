defmodule Crit.Usables.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Sql
  alias Crit.Usables.Hidden.Use
  alias Crit.Usables.Hidden.Use

  schema "reservations" do
    field :timespan, Timespan
    field :species_id, :id

    has_many :uses, Use

    field :animal_ids, {:array, :id}, virtual: true
    field :procedure_ids, {:array, :id}, virtual: true
    field :start_date, :date, virtual: true
    field :start_time, :time, virtual: true
    field :minutes, :integer, virtual: true
    timestamps()
  end

  @required [:start_date, :start_time, :minutes, :species_id, 
            :animal_ids, :procedure_ids]

  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> foreign_key_constraint(:species_id)
  end

  def creation_changeset(reservation, attrs) do
    changeset(reservation, attrs)
    |> populate_timespan
    |> put_uses
  end

  def create(attrs, institution) do
    creation_changeset(%__MODULE__{}, attrs)
    |> Sql.insert(institution)
  end

  defp put_uses(%{valid?: false} = changeset), do: changeset
  defp put_uses(changeset) do 
    %{animal_ids: animal_ids, procedure_ids: procedure_ids} = changeset.changes
    uses = Use.changesets_for_new_uses(animal_ids, procedure_ids)
    put_assoc(changeset, :uses, uses)
  end

  defp populate_timespan(%{valid?: false} = changeset), do: changeset
  defp populate_timespan(%{changes: changes} = changeset) do
    timespan = Timespan.from_date_time_and_duration(
      changes.start_date, changes.start_time, changes.minutes)
    put_change(changeset, :timespan, timespan)
  end
end
