defmodule Crit.Usables.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  alias Ecto.Timespan
  alias Crit.Sql
  import Crit.Sql.Transaction, only: [make_validation_step: 1]
  alias Crit.Usables.Hidden.Use
  alias Crit.Usables.{Animal, Procedure}
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

  # Note: there's deliberately no foreign key constraint added for
  # species_id. This is an "impossible error"
  def changeset(reservation, attrs) do
    reservation
    |> cast(attrs, @required)
    |> validate_required(@required)
    |> populate_timespan
    |> foreign_key_constraint(:species_id)
  end

  def create(attrs, institution) do
    validation = fn attrs -> changeset(%__MODULE__{}, attrs) end
    steps = [
      make_validation_step(validation),
      &bulk_insert_step/1,
    ]

    Sql.Transaction.run(attrs, institution, steps)
  end

  defp bulk_insert_step(%{original_changeset: changeset,
                          institution: institution}) do 
    %{animal_ids: animal_ids, procedure_ids: procedure_ids} = changeset.changes

    changeset
    |> put_assoc(:uses, Use.changesets_for_new_uses(animal_ids, procedure_ids))
    |> Sql.insert(institution)
  end

  defp populate_timespan(%{valid?: false} = changeset), do: changeset
  defp populate_timespan(%{changes: changes} = changeset) do
    timespan = Timespan.from_date_time_and_duration(
      changes.start_date, changes.start_time, changes.minutes)
    put_change(changeset, :timespan, timespan)
  end
end
