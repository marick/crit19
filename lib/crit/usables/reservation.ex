defmodule Crit.Usables.Reservation do
  use Ecto.Schema
  import Ecto.Changeset
  import Crit.Errors
  alias Ecto.Timespan
  alias Crit.Sql
  import Crit.Sql.Transaction, only: [make_validation_step: 1]
  alias Crit.Usables.Hidden.Use
  alias Ecto.Multi

  schema "reservations" do
    field :timespan, Timespan
    field :species_id, :id


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

    use_insertion_script_maker =
      make_use_insertion_script_maker(animal_ids, procedure_ids, institution)

    script = 
      Multi.new
      |> Multi.insert(:reservation, changeset, Sql.multi_opts(institution))
      |> Multi.merge(use_insertion_script_maker)

    script
    |> Sql.transaction(institution)
    |> Sql.Transaction.on_ok(extract: :reservation)
    |> Sql.Transaction.on_failed_step(fn
        (:reservation, failing_changeset) -> failing_changeset
        (_, failing_changeset) ->
          impossible_input("Animal or procedure id is invalid.",
            changeset: failing_changeset)
        end)
  end

  defp make_use_insertion_script_maker(animal_ids, procedure_ids, institution) do 
    fn tx_result ->

      reducer = fn use, multi_so_far ->
        Multi.insert(multi_so_far,
          use,  # We have to give a unique name for the result.
          Use.changeset_with_constraints(use),
          Sql.multi_opts(institution))
      end
      
      tx_result.reservation.id
      |> Use.reservation_uses(animal_ids, procedure_ids)
      |> Enum.reduce(Multi.new, reducer)
    end
  end

  defp populate_timespan(%{valid?: false} = changeset), do: changeset
  defp populate_timespan(%{changes: changes} = changeset) do
    timespan = Timespan.from_date_time_and_duration(
      changes.start_date, changes.start_time, changes.minutes)
    put_change(changeset, :timespan, timespan)
  end
end
